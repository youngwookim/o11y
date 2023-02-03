## Metrics

Prometheus Stack + Thanos

Thanos Sidecar vs Receiver, https://www.infracloud.io/blogs/prometheus-ha-thanos-sidecar-receiver/

![](https://d33wubrfki0l68.cloudfront.net/ae0539faf92bf98622200b4d5f8185f5cbe19b48/bcc67/assets/img/blog/prometheus-ha-with-thanos-sidecar-or-receiver/thanos_sidecar.png)

![](https://d33wubrfki0l68.cloudfront.net/e13332f2255f11204da99c005a96cdc4b5837056/1d50e/assets/img/blog/prometheus-ha-with-thanos-sidecar-or-receiver/thanos_receiver.png)

### Promethus + Thanos deployment with Thanos Receive

![](http://dockone.io/uploads/article/20200420/4d71f24188dfe26590eacd283c44919a.png)

Azure Blob Storage configmap for Thanos metrics:
```
# azure

kubectl create ns monitoring

kubectl -n monitoring create secret generic thanos-objstore-secret --from-file=objstore.yaml=thanos-objstore-azure.yaml

```

Thanos Deployment with Receive:

![](https://camo.githubusercontent.com/b0a661d7478b5f65500f704419796ff3ccb3c4aa5ea791c3db2cd2d587831867/68747470733a2f2f646f63732e676f6f676c652e636f6d2f64726177696e67732f642f652f32504143582d317654666b6f323759425f336162375a4c384f444e47357543637270714b78686d71617a336c572d7968474e335f6f4e786b547271586d77776c635a6a61576633634767414a494d34434d77776b45562f7075623f773d39363026683d373230)


![](http://dockone.io/uploads/article/20200420/4d71f24188dfe26590eacd283c44919a.png)

Grafana datasource:
- http://thanos-query.observability:9090

Ref. Sidecar vs. Receiver, https://www.infracloud.io/blogs/prometheus-ha-thanos-sidecar-receiver/

### Prometheus Operator

Components for k8s cluster:
- Prometheus Operator
- kube-state-metrics
- Prometheus Node Exporter


Prometheus operator for tenant:
```
$ helm upgrade --install -n observability prometheus prometheus-community/kube-prometheus-stack  \
--set prometheus.enabled=false \
--set grafana.enabled=false \
--set alertmanager.enabled=false

```

### Alertmanager

Standalone Alertmanager:
```
helm upgrade --install -n observability alertmanager prometheus-community/alertmanager \
--set persistence.size="5Gi" \
--set configmapReload.enabled=true

```

Update Alertmanager configs:
```
-- @monitoring
$ kubectl -n monitoring get secret alertmanager-prometheus-kube-prometheus-alertmanager -ojson | jq -r '.data["alertmanager.yaml"]' | base64 -D
$ kubectl -n monitoring create secret generic alertmanager-prometheus-kube-prometheus-alertmanager --from-literal=alertmanager.yaml="$(< alertmanager.yaml)" --dry-run -oyaml | kubectl -n monitoring replace secret --filename=-
$ kubectl rollout restart statefulset -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager

-- DSO
$ kubectl -n observability get cm alertmanager -ojson | jq -r '.data["alertmanager.yml"]'
$ kubectl -n observability create cm alertmanager --from-literal=alertmanager.yml="$(< alertmanager.yaml)" --dry-run -oyaml | kubectl -n observability replace cm --filename=-
$ kubectl rollout restart statefulset -n observability alertmanager

```

### Thanos

```
helm repo add bitnami https://charts.bitnami.com/bitnami

-- DSO
-- azure
kubectl create secret generic -n observability thanos-objstore-secret --from-file=objstore.yml=thanos-objstore-azure.yaml

-- s3 (minio)
kubectl create secret generic -n observability thanos-objstore-secret --from-file=objstore.yml=thanos-objstore-s3.yaml

helm upgrade --install -n observability thanos bitnami/thanos -f values-thanos-dso.yaml \
--set image.tag=0.26.0

ref. https://github.com/thanos-io/thanos/issues/3913

-- @grandview-dev (optional)
kubectl create secret generic -n monitoring thanos-objstore-secret --from-file=objstore.yml=thanos-objstore-azure.yaml
helm upgrade --install -n monitoring thanos bitnami/thanos -f values-thanos-dev.yaml

```

### kube-prometheus-stack (optional)

```
-- @grandview-dev
$ helm upgrade --install -n monitoring prometheus prometheus-community/kube-prometheus-stack  -f values-prom-grandview-dev.yaml \
--set prometheus.prometheusSpec.containers[0].name=prometheus \
--set prometheus.prometheusSpec.containers[0].readinessProbe.failureThreshold=1000

-- @grandview-devstfdemo
$ helm upgrade --install -n monitoring prometheus prometheus-community/kube-prometheus-stack  -f values-prom-grandview-devstgdemo.yaml \
--set prometheus.prometheusSpec.containers[0].name=prometheus \
--set prometheus.prometheusSpec.containers[0].readinessProbe.failureThreshold=1000

https://www.ibm.com/docs/en/cloud-private/3.2.x?topic=codes-monitoring
https://github.com/prometheus-operator/prometheus-operator/issues/3587
https://github.com/prometheus-operator/prometheus-operator/issues/3391

-- Pushgateway
$ helm upgrade --install -n monitoring prometheus-pushgateway prometheus-community/prometheus-pushgateway \
--set serviceMonitor.enabled=true \
--set serviceMonitor.namespace=monitoring

-- Per cluster
-- For Azure
$ helm upgrade --install -n monitoring prometheus prometheus-community/kube-prometheus-stack  \
--set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName="default" \
--set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage="30Gi" \
--set prometheus.prometheusSpec.resources.requests.memory="4Gi" \
--set prometheus.prometheusSpec.resources.requests.cpu="1.5" \
--set prometheus.prometheusSpec.retention="3d" \
--set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage="10Gi" \
--set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
--set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
--set kubeApiServer.enabled=false \
--set kubeControllerManager.enabled=false \
--set kubeEtcd.enabled=false \
--set kubeScheduler.enabled=false \
--set kubeProxy.enabed=false \
--set prometheus.prometheusSpec.containers[0].name=prometheus \
--set prometheus.prometheusSpec.containers[0].readinessProbe.failureThreshold=1000 \
--set grafana.enabled=false

-- without prometheus
--set prometheus.enabled=false

-- without altermanager
--set alertmanager.enabled=false

-- external alertmanager

prometheus:
## Alertmanagers to which alerts will be sent
    ## ref: https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#alertmanagerendpoints
    ##
    ## Default configuration will connect to the alertmanager deployed as part of this release
    ##
    alertingEndpoints: []
    # - name: ""
    #   namespace: ""
    #   port: http
    #   scheme: http
    #   pathPrefix: ""
    #   tlsConfig: {}
    #   bearerTokenFile: ""
    #   apiVersion: v2

```

Reload Prometheus config:
```
kubectl run curl -it --rm --image curlimages/curl -- sh
curl -X POST http://prometheus-kube-prometheus-prometheus.monitoring:9090/-/reload

```

## Kafka Metrics

- https://github.com/danielqsj/kafka_exporter
- https://grafana.com/grafana/dashboards/7589
- https://github.com/prometheus/jmx_exporter