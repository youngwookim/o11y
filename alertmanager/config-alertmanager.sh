set -ex

kubectl get secret -n monitoring

kubectl -n monitoring get secret alertmanager-prometheus-kube-prometheus-alertmanager -ojson | jq -r '.data["alertmanager.yaml"]' | base64 -D

kubectl -n monitoring create secret generic alertmanager-prometheus-kube-prometheus-alertmanager --from-literal=alertmanager.yaml="$(< alertmanager.yaml)" --dry-run -oyaml | kubectl -n monitoring replace secret --filename=-

kubectl rollout restart statefulset -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager
