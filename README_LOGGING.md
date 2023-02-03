## Logging

Prerequisites:
- OpenTelemetry Operator

## OTEL Collector

Collector for Logs, Traces & Metrics

### Kubernetes Cluster (Agent)

Receiver --> Exporter --> OTELCOL-DSO

Logs:
- Containers
- Applications
- Kubernetes Resources
- Kubernetes Events

```
-- Service Account
kubectl apply -n observability -f otelcol-sa-rbac.yaml

-- k8s dev
kubectl apply -n observability -f otelcol-k8s-dev.yaml

-- k8s devstgdemo
kubectl apply -n observability -f otelcol-k8s-devstgdemo.yaml

```

### DSO (Collector)

Collect logs, traces and metrics and then export telemetry data to backends

Receiver --> Backends

Backends:
- ClickHouse
- ElasticSearch
- Loki
- Kafka
- Azure Monitor
- DataDog
- ......

```
-- DSO
kubectl apply -n observability -f otelcol-dso.yaml

```

#### OTELCOL for Container logs on Kubernetes

- OTELCOL with Daemonset:
```
# prerequisite
- serviceAccount
 
-- daemonset
kubectl apply -n observability -f otelcol-containerlog-daemonset.yaml
kubectl delete -n observability -f otelcol-containerlog-daemonset.yaml

```

- OTELCOL with Fluent-bit (optional):
```
2022-03-17
"[parser] time string length is too long" --> https://github.com/fluent/fluent-bit/pull/5078

-- fluent-bit
helm repo add fluent https://fluent.github.io/helm-charts
helm repo update

helm upgrade --install -n observability fluent-bit fluent/fluent-bit -f values-fluentbit-container.yaml

Refs., https://stackoverflow.com/questions/57467070/how-can-fluent-bit-add-custom-metadata-to-each-event-message-being-sent-to-splun

```

- OTELCOL with Helm (optional):
```
-- https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-collector
-- helm
helm upgrade --install -n observability otelcol-container open-telemetry/opentelemetry-collector \
--set agentCollector.containerLogs.enabled=true

helm upgrade --install -n observability otelcol-container open-telemetry/opentelemetry-collector -f values-otelcol-container.yaml
helm uninstall -n observability otelcol-container
```

## Backends

### ClickHouse

1. DSO 
- TBD

2. Signoz
- for APM

### Loki (Simple Scalable)

```
-- azure blob storage
helm upgrade --install -n observability loki grafana/loki-simple-scalable  -f values-loki-simple-scalable-azure.yaml \
--set fullnameOverride="loki"

This chart requires persistence and object storage to work correctly.
Queries will not work unless you provide a `loki.config.common.storage` section with
a valid object storage (and the default `filesystem` storage set to `null`), as well
as a valid `loki.config.schema_config.configs` with an `object_store` that
matches the common storage section.

For example, to use MinIO as your object storage backend:

loki:
  config:
    common:
      storage:
        filesystem: null
        s3:
          endpoint: minio.minio.svc.cluster.local:9000
          insecure: true
          bucketnames: loki-data
          access_key_id: loki
          secret_access_key: supersecret
          s3forcepathstyle: true
    schema_config:
      configs:
        - from: "2020-09-07"
          store: boltdb-shipper
          object_store: s3
          schema: v11
          index:
            period: 24h
            prefix: loki_index_
```

### Loki Stack (optional)

```
-- Loki + Promtail with pvc
$ helm upgrade --install -n monitoring loki grafana/loki-stack  \
--set loki.persistence.enabled=true \
--set loki.persistence.size=50Gi \
--set loki.config.table_manager.retention_deletes_enabled=true  \
--set loki.config.table_manager.retention_period=72h \
--set loki.serviceMonitor.enabled=true

-- Loki + Promtail
-- azure blob storage
helm upgrade --install -n monitoring loki grafana/loki-stack  \
--set loki.persistence.enabled=true \
--set loki.persistence.size=50Gi \
--set loki.config.table_manager.retention_deletes_enabled=true  \
--set loki.config.table_manager.retention_period=72h \
--set loki.serviceMonitor.enabled=true \
--set loki.config.storage_config.boltdb_shipper.shared_store=azure \
--set loki.config.storage_config.azure.container_name="loki" \
--set loki.config.storage_config.azure.account_name="grandviewfs" \
--set loki.config.storage_config.azure.account_key="dk0Xjbnt1YinQj7FO0P+g1iTkh3Q9V/4bBg14wiK7u+KHt6bU0gS5IWC7UsHssq6u2GBseyQUVyEulfOYMUf6Q=="

Ref.:
- https://faun.pub/grafana-loki-with-azure-blob-storage-51bfdd68dfd0

```

## Grafana

LogQL:
```
{k8s_cluster_name="metatron-grandview-DevStgDemo"} |~ "level=error"

```

## Troubleshooting

- https://github.com/open-telemetry/opentelemetry-collector/blob/main/docs/troubleshooting.md
- ES
```
-- ES exporter

2022-02-22T02:23:51.836Z	error	elasticsearchexporter@v0.45.0/exporter.go:161	Drop event: failed to index event: struct { Type string "json:\"type\""; Reason string "json:\"reason\""; Cause struct { Type string "json:\"type\""; Reason string "json:\"reason\"" } "json:\"caused_by\"" }{Type:"mapper_parsing_exception", Reason:"object mapping for [Attributes.kubernetes.labels.app] tried to parse field [Attributes.kubernetes.labels.app] as object, but found a concrete value", Cause:struct { Type string "json:\"type\""; Reason string "json:\"reason\"" }{Type:"", Reason:""}}	{"kind": "exporter", "name": "elasticsearch", "attempt": 1, "status": 400}
github.com/open-telemetry/opentelemetry-collector-contrib/exporter/elasticsearchexporter.(*elasticsearchExporter).pushEvent.func1
	github.com/open-telemetry/opentelemetry-collector-contrib/exporter/elasticsearchexporter@v0.45.0/exporter.go:161

```

- https://github.com/uken/fluent-plugin-elasticsearch/issues/787
- https://github.com/lunardial/fluent-plugin-dedot_filter
- https://github.com/fluent/fluent-bit/issues/4386

## Refs.

- https://www.splunk.com/en_us/blog/devops/why-to-use-opentelemetry-processors-to-change-collected-backend-data.html
- ClickHouse
  - https://pixeljets.com/blog/clickhouse-vs-elasticsearch/
  - https://eng.uber.com/logging/
  - https://www.slideshare.net/VianneyFOUCAULT/meetup-a-successful-migration-from-elastic-search-to-clickhouse-179072416
  - https://www.slideshare.net/Altinity/a-practical-introduction-to-handling-log-data-in-clickhouse-by-robert-hodges-altinity-ceo
- OTELCOL
  - https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/fluentforwardreceiver
  - https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/lokiexporter
  - https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/exporter/lokiexporter/testdata/config.yaml
  - https://github.com/open-telemetry/opentelemetry-collector-releases
  - https://hub.docker.com/r/otel/opentelemetry-collector-contrib
  - https://opentelemetry.io/docs/collector/configuration/
  - https://lightstep.com/blog/understanding-static-site-performance-with-opentelemetry/
  - https://medium.com/opentelemetry/deploying-the-opentelemetry-collector-on-kubernetes-2256eca569c9
  - https://medium.com/opentelemetry/securing-your-opentelemetry-collector-1a4f9fa5bd6f
- Loki
   - https://github.com/grafana/loki/issues/1434
- cLoki
  - https://github.com/lmangani/cLoki
- Fluentbit
  - https://docs.aws.amazon.com/ko_kr/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-logs-FluentBit.html
  - https://rudimartinsen.com/2022/01/09/tce-fluent-bit/