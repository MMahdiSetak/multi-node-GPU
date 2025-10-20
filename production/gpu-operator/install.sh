kubectl create ns gpu-operator
kubectl label --overwrite ns gpu-operator pod-security.kubernetes.io/enforce=privileged

helm repo add nvidia https://helm.ngc.nvidia.com/nvidia &&
  helm repo update
helm search repo nvidia

helm install gpu-operator nvidia/gpu-operator -n gpu-operator --create-namespace --version=v25.3.3 --set driver.enabled=false --wait

# todo enable MIG based on configs

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
