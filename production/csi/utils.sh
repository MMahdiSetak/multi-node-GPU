# list disks
lsblk

sudo mkfs.ext4 -F -L data1 /dev/nvme1n1
sudo mkfs.ext4 -F -L data0 /dev/nvme0n1

blkid
/dev/nvme0n1: LABEL="data0" UUID="df32ad07-9971-463a-a89b-3f051bedb5d8" TYPE="ext4"
/dev/nvme1n1: LABEL="data1" UUID="5c88a083-a441-4967-a2b4-0b8be72274f7" TYPE="ext4"

sudo nano /etc/fstab
UUID=24c60c48-9add-4580-8665-4c9332d9d556 /data1 ext4 defaults 0 0
UUID=dc7145b8-f370-42dc-9130-2d3dc5d5bfdc /var/openebs/local ext4 defaults 0 0
sudo mount -a

kubectl patch storageclass local-path \
  -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}'

kubectl patch storageclass openebs-lvmpv \
  -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'

# LVM2 requierments
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
