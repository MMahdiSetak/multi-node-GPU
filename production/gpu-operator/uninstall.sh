helm uninstall gpu-operator -n gpu-operator
kubectl delete namespace gpu-operator

kubectl get clusterrole | grep gpu-operator
kubectl get clusterrolebinding | grep gpu-operator
kubectl delete clusterrole gpu-operator-node-feature-discovery gpu-operator-node-feature-discovery-gc gpu-operator-node-feature-discovery gpu-operator-node-feature-discovery-gc
kubectl delete clusterrolebinding gpu-operator gpu-operator-node-feature-discovery gpu-operator-node-feature-discovery-gc gpu-operator-node-feature-discovery gpu-operator-node-feature-discovery-gc

kubectl get crd | grep -i nvidia
kubectl delete crd clusterpolicies.nvidia.com nvidiadrivers.nvidia.com