# kubectl patch deployment openebs-localpv-provisioner -n openebs --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/env/4/value", "value": "/data1"}]'
# helm install openebs openebs/openebs --set ndm.enabled=true --namespace openebs --create-namespace

helm repo add openebs https://openebs.github.io/openebs
helm repo update
helm install openebs --namespace openebs openebs/openebs --set engines.replicated.mayastor.enabled=false --create-namespace
kubectl annotate storageclass openebs-hostpath storageclass.kubernetes.io/is-default-class=true
