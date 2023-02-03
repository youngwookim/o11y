# Clickhouse-operator

https://github.com/Altinity/clickhouse-operator

```
# E.g., 
kubectl apply -n observability -f clickhouse-cloki.yaml

```

## Metrics for CH

https://kb.altinity.com/altinity-kb-setup-and-maintenance/altinity-kb-monitoring/

https://github.com/Altinity/clickhouse-operator/blob/master/docs/prometheus_setup.md

https://altinity.com/blog/2020/5/5/monitoring-clickhouse-kubernetes-prometheus-grafana

https://github.com/Altinity/clickhouse-operator/tree/master/grafana-dashboard

## CH & OpenTelemetry

https://clickhouse.com/docs/en/operations/opentelemetry/


-- TODO
```
CREATE MATERIALIZED VIEW default.zipkin_spans
ENGINE = URL('http://otelcol-dso-collector.observability:9411/api/v2/spans', 'JSONEachRow')
SETTINGS output_format_json_named_tuples_as_objects = 1,
    output_format_json_array_of_rows = 1 AS
SELECT
    lower(hex(trace_id)) AS traceId,
    case when parent_span_id = 0 then '' else lower(hex(parent_span_id)) end AS parentId,
    lower(hex(span_id)) AS id,
    operation_name AS name,
    start_time_us AS timestamp,
    finish_time_us - start_time_us AS duration,
    cast(tuple('clickhouse'), 'Tuple(serviceName text)') AS localEndpoint,
    cast(tuple(
        attribute.values[indexOf(attribute.names, 'db.statement')]),
        'Tuple("db.statement" text)') AS tags
FROM system.opentelemetry_span_log

```