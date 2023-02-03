# Grafana

Prerequisites:
- keycloak

## Grafana 'MELT' (for DSO)

```
$ helm upgrade --install -n observability grafana grafana/grafana -f values-grafana.yaml \
--set image.tag="8.5.0" \
--set persistence.enabled=true \
--set adminUser=admin \
--set adminPassword=mypassword \
--set serviceMonitor.enabled=true \
--set sidecar.dashboards.enabled=true \
--set sidecar.dashboards.searchNamespace=ALL

# ingress
kubectl apply -f grafana-*-ingress.yaml

# AuthN: user
https://melt.dev.metatron.app

# AuthN: admin
https://melt.dev.metatron.app/login?disableAutoLogin

```
## grafana-dev (for development)

```
$ helm upgrade --install -n observability grafana grafana/grafana -f values-grafana.yaml \
--set persistence.enabled=true \
--set adminUser=admin \
--set adminPassword=mypassword \
--set serviceMonitor.enabled=true \
--set sidecar.dashboards.enabled=true \
--set sidecar.dashboards.searchNamespace=ALL

# ingress
kubectl apply -f grafana-dev-ingress.yaml

https://grafana.dev.metatron.app

# AuthN: admin
https://grafana.dev.metatron.app/login?disableAutoLogin
```

## Data sources

- Prometheus: Grafana > Data Source > Prometheus, HTTP URL --> http://prometheus-kube-prometheus-prometheus:9090
- Loki: Grafana > Data Source > Loki, HTTP URL --> http://loki:3100/

Notification channel:
- Prometheus Alertmanager: http://prometheus-kube-prometheus-alertmanager.monitoring.svc:9093

## Troubleshooting

Text Panel with iframe:
- https://github.com/jangaraj/grafana-iframe
- SigNoz
```
Transparent background: on

mode: html

contents:
<iframe style="position:absolute;height:100%;width:100%;border:none" src="https://apm.dev.metatron.app/" />

```

Log panel:
- https://github.com/grafana/clickhouse-datasource/issues/23

- https://github.com/grafana/grafana/issues/10786#issuecomment-734447429
```
Workaround
Under this lines

"templating": {
      "list": [
insert this:

{
            "hide": 0,
            "label": "datasource",
            "name": "DS_PROMETHEUS",
            "options": [],
            "query": "prometheus",
            "refresh": 1,
            "regex": "",
            "type": "datasource"
          },
```

## Grafana Dashboards

See [dashboards](./dashboards/README.md)
```
$ kubectl apply -n monitoring -f ./dashboards/

```

https://promcat.io/
