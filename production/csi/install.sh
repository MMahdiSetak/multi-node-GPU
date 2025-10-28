helm repo add openebs https://openebs.github.io/openebs
helm repo update
helm install openebs --namespace openebs openebs/openebs \
    --set engines.replicated.mayastor.enabled=false \
    --set loki.enabled=false \
    --create-namespace
#kubectl patch deployment openebs-localpv-provisioner -n openebs --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/env/4/value", "value": "/home/admin/data/openebs"}]'
kubectl patch sc openebs-hostpath --type='json' -p='[{"op": "replace", "path": "/metadata/annotations/cas.openebs.io~1config", "value": "- name: StorageType\n  value: \"hostpath\"\n- name: BasePath\n  value: \"/home/admin/data/openebs\""}]'
kubectl annotate storageclass openebs-hostpath storageclass.kubernetes.io/is-default-class=true


# --set loki.localpvScConfig.loki.basePath="/home/admin/data/openebs/localpv-hostpath/loki" \
# --set loki.localpvScConfig.minio.basePath="/home/admin/data/openebs/localpv-hostpath/minio" \