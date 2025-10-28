#kubectl delete pvc -A --all
#kubectl delete pv --all
#kubectl patch pv pvc-b03d18f9-6047-4fd9-b2cb-ca7dd58c96a1 -p '{"metadata":{"finalizers":null}}'

helm uninstall openebs -n openebs
kubectl delete namespace openebs
