## Tracing

Prerequisites:
- cert-manager
- OpenTelemetry Operator & Collector
- ClickHouse Operator
- SigNoz APM
- Jaeger Operator, https://github.com/jaegertracing/jaeger-operator

## Tracing for Knative

Knative --> (ZIPKIN Protocol) --> OTELCOL (Agent) --> OTELCOL (Collector, DSO) --> Jaeger,SigNoz & etc.

## OpenTelemetry + SigNoz (+ ClickHouse)

See [apm/README.md](apm/README.md)

## OpenTelemetry + Jaeger (+ ClickHouse)

Prerequisites:
- ClickHouse database 'jaeger'

```
kubectl apply -n observability -f jaeger-clickhouse.yaml

-- knative tracing
for ns in knative-eventing knative-serving; do
  kubectl patch --namespace "$ns" configmap/config-tracing \
   --type merge \
   --patch '{"data":{"backend":"zipkin", "zipkin-endpoint":"http://otelcol-k8s-collector.observability:9411/api/v2/spans", "sample-rate":"0.1", "debug": "false"}}'
done
```

Grafana datasource:
- http://jaeger-query.observability:16686

## Test

```
kubectl apply -f - <<EOF
apiVersion: sources.knative.dev/v1
kind: ContainerSource
metadata:
  name: heartbeats
  namespace: observability
spec:
  template:
    spec:
      containers:
        - image: gcr.io/knative-nightly/knative.dev/eventing/cmd/heartbeats:latest
          name: heartbeats
          args:
            - --period=1
          env:
            - name: POD_NAME
              value: "heartbeats"
            - name: POD_NAMESPACE
              value: "observability"
            # OTELCOL (agent)
            - name: K_CONFIG_TRACING
              value: '{"backend":"zipkin","debug":"true","zipkin-endpoint":"http://otelcol-k8s-collector.observability:9411//api/v2/spans"}'
              
  sink:
    ref:
      apiVersion: serving.knative.dev/v1
      kind: Service
      name: event-display
EOF

kubectl apply -f - <<EOF
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: event-display
  namespace: observability
spec:
  template:
    spec:
      containers:
        - image: gcr.io/knative-nightly/knative.dev/eventing/cmd/event_display:latest
          env:
            # OTELCOL (agent)
            - name: K_CONFIG_TRACING
              value: '{"backend":"zipkin","debug":"false","zipkin-endpoint":"http://otelcol-k8s-collector.observability:9411/api/v2/spans"}'
EOF

```

## Tracing + Nginx Ingress Controller via OTELCOL

https://kubernetes.github.io/ingress-nginx/user-guide/third-party-addons/opentracing/

```
$ kubectl edit cm -n ingress-nginx ingress-nginx-controller

enable-opentracing: "true"

# Jaeger
#jaeger-collector-host: jaeger-collector.observability.svc.cluster.local
# otelcol jaeger receiver
#jaeger-collector-host: otelcol-k8s-collector.observability.svc.cluster.local
#jaeger-collector-port: "14250"
#jaeger-service-name: "ingress-nginx"

# OTELCOL - zipkin
zipkin-collector-host: otelcol-k8s-collector.observability.svc.cluster.local
zipkin-collector-port: "9411"
zipkin-service-name: "ingress-nginx"
zipkin-sample-rate: "0.1"

To enable or disable instrumentation for a single Ingress, use the enable-opentracing annotation:


kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/enable-opentracing: "true"

```

## Refs.

- https://knative.dev/blog/articles/distributed-tracing/
- https://awkwardferny.medium.com/setting-up-distributed-tracing-with-opentelemetry-jaeger-in-kubernetes-ingress-nginx-cfdda7d9441d
- https://uptrace.dev/
