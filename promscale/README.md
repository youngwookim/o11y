# Promscale

- https://github.com/timescale/tobs
- https://github.com/timescale/promscale

![](https://github.com/timescale/promscale/raw/master/docs/assets/promscale-arch.png)

```
# tobs cli
curl --proto '=https' -A 'tobs' --tlsv1.2 -sSLf  https://tsdb.co/install-tobs-sh |sh

helm repo add timescale https://charts.timescale.com/
helm repo update

```

```
tobs install --only-secrets --namespace observability

helm upgrade --install -n observability tobs timescale/tobs -f values-tobs.yaml \
--set promscale.connection.password="bSRWD72dBx"

```

```
TimescaleDB can be accessed via port 5432 on the following DNS name from within your cluster:
tobs.observability.svc.cluster.local
To get your password for superuser run:
    # superuser password
    PGPASSWORD_POSTGRES=$(kubectl get secret --namespace observability tobs-timescaledb-passwords -o jsonpath="{.data.postgres}" | base64 --decode)

    # admin password
    PGPASSWORD_ADMIN=$(kubectl get secret --namespace observability tobs-timescaledb-passwords -o jsonpath="{.data.admin}" | base64 --decode)

To connect to your database, chose one of these options:

1. Run a postgres pod and connect using the psql cli:
    # login as superuser
    kubectl run -i --tty --rm psql --image=postgres \
      --env "PGPASSWORD=$PGPASSWORD_POSTGRES" \
      --command -- psql -U postgres \
      -h tobs.observability.svc.cluster.local postgres

    # login as admin
    kubectl run -i --tty --rm psql --image=postgres \
      --env "PGPASSWORD=$PGPASSWORD_ADMIN" \
      --command -- psql -U admin \
      -h tobs.observability.svc.cluster.local postgres

2. Directly execute a psql session on the master node
   MASTERPOD="$(kubectl get pod -o name --namespace observability -l release=tobs,role=master)"
   kubectl exec -i --tty --namespace observability ${MASTERPOD} -- psql -U postgres
```

```
kubectl run -i --tty --rm psql --image=postgres \
      --env "PGPASSWORD=bSRWD72dBx" \
      --command -- psql -U postgres \
      -h tobs.observability.svc.cluster.local postgres

# https://docs.timescale.com/timescaledb/latest/how-to-guides/hyperfunctions/install-toolkit/#install-toolkit-on-managed-service-for-timescaledb

> CREATE EXTENSION timescaledb_toolkit;

```

----

Prometheus:
- http://{{ .Release.Name }}-promscale-connector.{{ .Release.Namespace }}.svc.cluster.local:9201

Grafana datasource:
- http://tobs-promscale-connector.observability:9201

## Jaeger

```
kubectl apply -n observability -f jaeger-query-promscale.yaml
```

- promscaleTracesQueryEndPoint: "{{ .Release.Name }}-promscale-connector.{{ .Release.Namespace }}.svc.cluster.local:9202"

http://tobs-jaeger.observability:16686

## Dashboards

APM:
- https://github.com/timescale/tobs/tree/master/chart/dashboards

SPM:
- https://github.com/timescale/opentelemetry-demo/tree/main/grafana/dashboards

## Metrics

https://github.com/timescale/promscale/blob/master/docs/metrics.md

```
kubectl annotate pods --overwrite -n observability -l app.kubernetes.io/name=promscale-connector \
prometheus.io/scrape=true prometheus.io/path=/metrics prometheus.io/port=9201
```

## Monitoring TimescaleDB

- https://grafana.com/grafana/dashboards/455
- https://gitlab.com/anarcat/grafana-dashboards/blob/master/postgresql.json

## Retention

Metrics:
- https://github.com/timescale/promscale/blob/master/docs/metric_deletion_and_retention.md

Traces:
- https://github.com/timescale/promscale/blob/master/docs/tracing.md

```
SELECT EXTRACT(day FROM _prom_catalog.get_metric_retention_period('')) AS retention_days;

90 days <- default

-- 30
SELECT prom_api.set_default_retention_period(INTERVAL '1 day' * 30)

-- retention for trace
SELECT ps_trace.get_trace_retention_period();

30 days <- default

SELECT ps_trace.set_trace_retention_period(15 * INTERVAL '1 day');

```

## Refs.

- https://github.com/timescale/timescaledb-kubernetes/tree/master/charts/timescaledb-single