#!/usr/bin/env bash
set -euo pipefail

helm upgrade --install rook-ceph ./rook-ceph-v1.18.8.tgz \
  --namespace rook-ceph \
  --create-namespace \
  -f operator-values.yaml \
  --set image.repository="${REGISTRY}/rook/ceph" \
  --set csi.cephcsi.repository="${REGISTRY}/cephcsi/cephcsi" \
  --set csi.registrar.repository="${REGISTRY}/sig-storage/csi-node-driver-registrar" \
  --set csi.provisioner.repository="${REGISTRY}/sig-storage/csi-provisioner" \
  --set csi.snapshotter.repository="${REGISTRY}/sig-storage/csi-snapshotter" \
  --set csi.attacher.repository="${REGISTRY}/sig-storage/csi-attacher" \
  --set csi.resizer.repository="${REGISTRY}/sig-storage/csi-resizer" \
  --set csi.csiAddons.repository="${REGISTRY}/csiaddons/k8s-sidecar"

helm upgrade --install rook-ceph-cluster ./rook-ceph-cluster-v1.18.8.tgz \
  --namespace rook-ceph \
  --create-namespace \
  -f cluster-values.yaml \
  --set operatorNamespace=rook-ceph \
  --set cephImage.repository="${REGISTRY}/ceph/ceph" \
  --set toolbox.image="${REGISTRY}/ceph/ceph:v19.2.3"

cat <<EOF | kubectl apply -f - 
apiVersion: v1
kind: Service
metadata:
  name: rook-ceph-mgr-dashboard-loadbalancer
  namespace: rook-ceph
  labels:
    app: rook-ceph-mgr
    rook_cluster: rook-ceph
  annotations:
    "lbipam.cilium.io/ips": "${CEPH_IP}"
spec:
  ports:
    - name: dashboard
      port: 80
      protocol: TCP
      targetPort: 7000
  selector:
    app: rook-ceph-mgr
    mgr_role: active
    rook_cluster: rook-ceph
  sessionAffinity: None
  type: LoadBalancer
EOF

kubectl annotate storageclass ceph-block storageclass.kubernetes.io/is-default-class=true
while ! kubectl -n rook-ceph get secret rook-ceph-dashboard-password >/dev/null 2>&1; do
  sleep 1
done
kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo