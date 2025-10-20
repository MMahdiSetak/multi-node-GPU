kubectl create ns gpu-operator
kubectl label --overwrite ns gpu-operator pod-security.kubernetes.io/enforce=privileged
# kubectl get nodes -o json | jq '.items[].metadata.labels | keys | any(startswith("feature.node.kubernetes.io"))'

helm repo add nvidia https://helm.ngc.nvidia.com/nvidia &&
  helm repo update
helm search repo nvidia

helm install gpu-operator nvidia/gpu-operator -n gpu-operator --create-namespace --version=v25.3.3 --set driver.enabled=false --wait
helm upgrade gpu-operator nvidia/gpu-operator -n gpu-operator --set driver.enabled=true --set mig.strategy=single
# driver.version=570.86.15
# driver.useOpenKernelModules=true
# nvidia.com/mig.config=all-disabled
# kubectl label nodes worker-g01 nvidia.com/mig.config=all-1g.10gb --overwrite
# kubectl get node worker-g01 -o=jsonpath='{.metadata.labels}' | jq . | grep nvidia

kubectl patch clusterpolicies.nvidia.com/cluster-policy \
  --type='json' \
  -p='[{"op":"replace", "path":"/spec/mig/strategy", "value":"mixed"}]'
kubectl label nodes worker-g01 nvidia.com/mig.config=all-balanced --overwrite

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

## delete and cleanup:

helm list -A
helm uninstall gpu-operator -n gpu-operator
kubectl delete namespace gpu-operator

kubectl get clusterrole | grep gpu-operator
kubectl get clusterrolebinding | grep gpu-operator
kubectl delete clusterrole gpu-operator-node-feature-discovery gpu-operator-node-feature-discovery-gc gpu-operator-node-feature-discovery gpu-operator-node-feature-discovery-gc
kubectl delete clusterrolebinding gpu-operator gpu-operator-node-feature-discovery gpu-operator-node-feature-discovery-gc gpu-operator-node-feature-discovery gpu-operator-node-feature-discovery-gc

kubectl get crd | grep -i nvidia
kubectl delete crd clusterpolicies.nvidia.com nvidiadrivers.nvidia.com

# helm install gpu-operator nvidia/gpu-operator \
#     -n gpu-operator --create-namespace \
#     nvidia/gpu-operator \
#     --version=v24.9.2 \
#     --set mig.strategy=single --wait
