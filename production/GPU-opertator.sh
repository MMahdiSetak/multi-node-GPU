helm repo add nvidia https://helm.ngc.nvidia.com/nvidia &&
    helm repo update
helm search repo nvidia

helm install gpu-operator nvidia/gpu-operator -n gpu-operator --create-namespace --version=v24.9.2 --set driver.enabled=false --wait

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

helm list -A
helm uninstall gpu-operator -n gpu-operator
kubectl delete namespace gpu-operator

kubectl get clusterrole | grep gpu-operator
kubectl get clusterrolebinding | grep gpu-operator
kubectl delete clusterrole gpu-operator-node-feature-discovery gpu-operator-node-feature-discovery-gc gpu-operator-node-feature-discovery gpu-operator-node-feature-discovery-gc
kubectl delete clusterrolebinding gpu-operator gpu-operator-node-feature-discovery gpu-operator-node-feature-discovery-gc gpu-operator-node-feature-discovery gpu-operator-node-feature-discovery-gc

kubectl get crd | grep -i nvidia
kubectl delete crd clusterpolicies.nvidia.com nvidiadrivers.nvidia.com

# helm install --wait --generate-name \
#     -n gpu-operator --create-namespace \
#     nvidia/gpu-operator \
#     --version=v24.9.2 \
#     --set driver.enabled=false
