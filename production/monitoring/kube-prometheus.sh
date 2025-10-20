kubectl apply --server-side -f manifests/setup
#kubectl apply --server-side -f manifests/openebs-addons
kubectl wait \
	--for condition=Established \
	--all CustomResourceDefinition \
	--namespace=monitoring
kubectl apply -f manifests/

kubectl --namespace monitoring port-forward svc/prometheus-k8s 9090
kubectl --namespace monitoring port-forward --address 0.0.0.0 svc/grafana 3000
# kubectl -n monitoring patch svc grafana \
# 	--type='merge' \
# 	-p '{"spec": {"type": "NodePort"}}'

kubectl --namespace monitoring port-forward svc/alertmanager-main 9093

# kubectl --namespaces gpu-operator port-forward svc/nvidia-dcgm-exporter 9095

# kubectl delete --ignore-not-found=true -f manifests/ -f manifests/setup

kubectl -n gpu-operator port-forward --address 0.0.0.0 svc/nvidia-dcgm-exporter 9400
