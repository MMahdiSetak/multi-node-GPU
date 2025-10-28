# kubectl patch deployment openebs-localpv-provisioner -n openebs --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/env/4/value", "value": "/home/admin/data/openebs"}]'
# helm install openebs openebs/openebs --set ndm.enabled=true --namespace openebs --create-namespace

helm repo add openebs https://openebs.github.io/openebs
helm repo update
helm install openebs --namespace openebs openebs/openebs \
    --set engines.replicated.mayastor.enabled=false \
    --set loki.localpvScConfig.loki.basePath="/home/admin/data/localpv-hostpath/loki" \
    --create-namespace
helm upgrade openebs --namespace openebs openebs/openebs --set engines.replicated.mayastor.enabled=true 
kubectl annotate storageclass openebs-hostpath storageclass.kubernetes.io/is-default-class=true

# kubectl label node <YOUR-NODE-NAME >openebs.io/engine=lvm

# kubectl edit sc openebs-hostpath

kubectl patch deployment sc openebs-hostpath --type='json' -p='[{"op": "replace", "path": "/metadata/annotations/cas.openebs.io/config/1/value", "value": "/home/admin/data/openebs"}]'
#https://openebs.github.io/openebs/

kubectl patch sc openebs-hostpath --type='json' -p='[{"op": "replace", "path": "/metadata/annotations/cas.openebs.io~1config", "value": "- name: StorageType\n  value: \"hostpath\"\n- name: BasePath\n  value: \"/home/admin/data/openebs\""}]'

apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    cas.openebs.io/config: |
      - name: StorageType
        value: "hostpath"
      - name: BasePath
        value: "/var/openebs/local"
    meta.helm.sh/release-name: openebs
    meta.helm.sh/release-namespace: openebs
    openebs.io/cas-type: local
  creationTimestamp: "2025-10-26T15:05:15Z"
  labels:
    app.kubernetes.io/managed-by: Helm
  name: openebs-hostpath
  resourceVersion: "12538484"
  uid: b4069d9a-89ba-4638-bb94-dedb2e346acd
provisioner: openebs.io/local
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer