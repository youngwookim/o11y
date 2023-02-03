# OpenTelemetry Collector

Prerequisites:
- OpenTelemetry Operator
- TLS cert for "*.dev.metatron.app"

## Deploying OTELCOLs

```
$ kustomize build ./overlays/[dev|devstgdemo|kic-dev] | kubectl apply -f -

```