# kubectl patch deployment openebs-localpv-provisioner -n openebs --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/env/4/value", "value": "/data1"}]'
# helm install openebs openebs/openebs --set ndm.enabled=true --namespace openebs --create-namespace

helm repo add openebs https://openebs.github.io/openebs
helm repo update
helm install openebs --namespace openebs openebs/openebs --set engines.replicated.mayastor.enabled=false --create-namespace
kubectl annotate storageclass openebs-hostpath storageclass.kubernetes.io/is-default-class=true

# kubectl label node <YOUR-NODE-NAME >openebs.io/engine=lvm

dnf install -y lvm2
modprobe dm-snapshot
lsmod | grep dm_snapshot

pvcreate /dev/nvme0n1

sudo vgcreate openebs-vg /dev/nvme0n1 #$LOOPDEV
#sudo vgextend openebs-vg $LOOPDEV
vgdisplay openebs-vg

cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-lvmpv
allowVolumeExpansion: true
parameters:
  storage: "lvm"
  volgroup: "openebs-vg"
provisioner: local.csi.openebs.io
allowedTopologies:
- matchLabelExpressions:
  - key: kubernetes.io/hostname
    values:
      - worker-g01
EOF

cat <<EOF | kubectl apply -f -
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: csi-lvmpv
spec:
  storageClassName: openebs-lvmpv
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 4Gi
EOF
