# Observability

## Prerequisites

- Kubernetes
- cert-manager
- Kafka
- Knative
- Tekton

## M.E.L.T

Metrics, Events, Logging & Tracing

### Related topics

#### OpenTelemetry

https://opentelemetry.io/

- OpenTelemetry Operator:
```
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml

# via Helm
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

helm upgrade --install --namespace opentelemetry-operator-system opentelemetry-operator open-telemetry/opentelemetry-operator --create-namespace

```

- Auto instrumentation for `dev` namespace
```
$ kubectl apply -f - <<EOF
apiVersion: opentelemetry.io/v1alpha1
kind: Instrumentation
metadata:
  name: my-instrumentation
  namespace: dev
spec:
  exporter:
    endpoint: "http://[OTELCOL]:4317"
  propagators:
    - tracecontext
    - baggage
    - b3
  sampler:
    type: parentbased_traceidratio
    argument: "0.1"
  java:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:latest
  nodejs:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-nodejs:latest
  python:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-python:latest
EOF
```

Auto-instrumentation for java app.:
```
kubectl patch -n grandview-dev deployment.apps/myapp -p '{"spec": {"template": {"metadata": {"annotations": {"instrumentation.opentelemetry.io/inject-java": "true"}}}}}'

```

Ref. https://medium.com/opentelemetry/using-opentelemetry-auto-instrumentation-agents-in-kubernetes-869ec0f42377


### Prometheus / Thanos on Kubernetes for metrics

See [README_METRICS.md](README_METRICS.md)

### Logging

See [README_LOGGING.md](README_LOGGING.md)

### Tracing

See [README_TRACING.md](README_TRACING.md)

#### Dashboards

See [grafana/README.md](grafana/README.md)

Grafana on Kubernetes:
- https://github.com/grafana-operator/grafana-operator

## Misc.

- Opensource APM / SPM
  - Apache SkyWalking
  - SigNoz
  - Jaeger
- tracetest

## Refs.

- OpenTelemetry
  - https://opentelemetry.io/
  - https://opensearch.org/blog/technical-post/2021/12/distributed-tracing-pipeline-with-opentelemetry/
  - https://medium.com/opentelemetry/using-opentelemetry-auto-instrumentation-agents-in-kubernetes-869ec0f42377
- https://www.m-f.ch/blog/monitor-azure-kubernetes-cluster
- https://rancher.com/blog/2020/custom-monitoring
- https://tanzu.vmware.com/developer/guides/spring-prometheus/
- https://github.com/opsgenie/kubernetes-event-exporter
- Thanos
  - https://itnext.io/monitoring-kubernetes-workloads-with-prometheus-and-thanos-4ddb394b32c
  - https://techcommunity.microsoft.com/t5/apps-on-azure-blog/store-prometheus-metrics-with-thanos-azure-storage-and-azure/ba-p/3067849
  - https://mattermost.com/blog/monitoring-cloud-environments-at-scale-with-prometheus-and-thanos/
  - https://tanzu.vmware.com/developer/guides/prometheus-multicluster-monitoring/
  - https://particule.io/en/blog/thanos-monitoring/
  - http://dockone.io/article/10053
- https://blog.naver.com/PostView.naver?blogId=sbckcorp&logNo=222425425647&parentCategoryNo=&categoryNo=47&viewDate=&isShowPopularPosts=true&from=search
- https://aws.amazon.com/ko/blogs/opensource/aws-one-observability-demo-workshop-whats-new-with-prometheus-grafana-and-opentelemetry/
- https://epsagon.com/tools/introduction-to-opentelemetry-overview/
- https://epsagon.com/observability/opentelemetry-best-practices-overview-part-2-2/
- https://blog.freshtracks.io/a-deep-dive-into-kubernetes-metrics-part-3-container-resource-metrics-361c5ee46e66
- OpenTelemetry & Kubernetes
  - https://github.com/apache/skywalking-showcase/tree/main/deploy/platform/kubernetes/feature-kubernetes-monitor
  - https://github.com/prometheus/prometheus/blob/main/documentation/examples/prometheus-kubernetes.yml
