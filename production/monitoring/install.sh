kubectl create namespace monitoring

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: grafana-oauth-secret
  namespace: monitoring
type: Opaque
stringData:
  client_secret: LU5fS1isflKSCFYCcciuwhxsMxshNdky
EOF


kubectl apply --server-side -f ../monitoring/manifests/setup
kubectl wait \
	--for condition=Established \
	--all CustomResourceDefinition \
	--namespace=monitoring
kubectl apply -f ../monitoring/manifests/


kubectl apply -f - <<'EOF'
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: nvidia-dcgm-exporter
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: nvidia-dcgm-exporter 
  namespaceSelector:
    matchNames:
    - gpu-operator
  endpoints:
  - port: gpu-metrics
    interval: 5s
    path: /metrics
EOF


kubectl delete NetworkPolicy grafana -n monitoring