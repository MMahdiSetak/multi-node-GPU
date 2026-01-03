helm upgrade --install rook-ceph ./rook-ceph-v1.18.8.tgz \
  --namespace rook-ceph \
  --create-namespace \
  -f operator-values.yaml \
  --set csi.cephcsiOperator.repository="worker-g02:5000/cephcsi/ceph-csi-operator" \
  --set image.repository="worker-g02:5000/rook/ceph" \
  --set csi.cephcsi.repository="worker-g02:5000/cephcsi/cephcsi" \
  --set csi.registrar.repository="worker-g02:5000/sig-storage/csi-node-driver-registrar" \
  --set csi.provisioner.repository="worker-g02:5000/sig-storage/csi-provisioner" \
  --set csi.snapshotter.repository="worker-g02:5000/sig-storage/csi-snapshotter" \
  --set csi.attacher.repository="worker-g02:5000/sig-storage/csi-attacher" \
  --set csi.resizer.repository="worker-g02:5000/sig-storage/csi-resizer" \
  --set csi.csiAddons.repository="worker-g02:5000/csiaddons/k8s-sidecar" \
  --wait --timeout 5m


helm uninstall rook-ceph -n rook-ceph



helm upgrade --install rook-ceph-cluster ./rook-ceph-cluster-v1.18.8.tgz \
  --namespace rook-ceph \
  --create-namespace \
  -f cluster-values.yaml \
  --set operatorNamespace=rook-ceph

helm delete rook-ceph-cluster -n rook-ceph

kubectl delete namespace rook-ceph


kubectl -n rook-ceph logs -l app=rook-ceph-operator -f

export dev=/dev/sdc
umount $dev* 2>/dev/null || true
wipefs -a -f $dev
sgdisk --zap-all $dev
# Overwrite BlueStore magic locations
blkdiscard --zeroout $dev
# dd if=/dev/zero of=$dev bs=1M oflag=direct,sync status=progress
# for offset in 0 1024 10240 102400 1024000; do
#     dd if=/dev/zero of=$dev bs=1M count=64 seek=$offset oflag=direct,sync status=progress || true
# done
# dd if=/dev/zero of=$dev bs=1M count=10 oflag=direct
# dd if=/dev/zero of=$dev bs=1M count=10 seek=$(( $(blockdev --getsize64 $dev) / 1048576 - 10 )) oflag=direct

# Reset OSDs by adding an annotation to the CephCluster
kubectl -n rook-ceph patch cephcluster rook-ceph --type=merge -p '{"metadata":{"annotations":{"osd-reset":"'$(date +%s)'"}}}'