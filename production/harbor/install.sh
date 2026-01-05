REGISTRY="worker-g02:5000"

cat << EOF | helm upgrade --install harbor-db ./postgresql-18.2.0.tgz -n harbor --create-namespace --values -
global:
  imageRegistry: "${REGISTRY}"
  security:
    allowInsecureImages: true

auth:
  username: harbor
  password: VeryStrongPostgresPass123
  database: registry
  postgresPassword: AnotherVeryStrongPostgresPass123   # optional but good to set

primary:
  persistence:
    enabled: true
    storageClass: ceph-block
    size: 50Gi
  resources:
    requests:
      memory: 512Mi
      cpu: 500m
    limits:
      memory: 2Gi
      cpu: 2000m

volumePermissions:
  enabled: true
EOF

helm upgrade --install harbor-redis ./redis-24.1.0.tgz -n harbor \
  --set global.imageRegistry="${REGISTRY}" \
  --set global.security.allowInsecureImages=true \
  --set auth.password='VeryStrongRedisPass123' \
  --set architecture=replication \
  --set master.persistence.enabled=true \
  --set master.persistence.storageClass=ceph-block \
  --set master.persistence.size=20Gi \
  --set replica.replicaCount=3 \
  --set replica.persistence.enabled=true \
  --set replica.persistence.storageClass=ceph-block \
  --set replica.persistence.size=20Gi


cat <<EOF | kubectl apply -f -
apiVersion: ceph.rook.io/v1
kind: CephObjectStore
metadata:
  name: harbor-rgw
  namespace: rook-ceph
spec:
  metadataPool:
    replicated:
      size: 1
  dataPool:
    replicated:
      size: 1
  preservePoolsOnDelete: true
  gateway:
    instances: 2
    port: 80
EOF

cat <<EOF | kubectl apply -f - 
apiVersion: ceph.rook.io/v1
kind: CephObjectStoreUser
metadata:
  name: harbor-user
  namespace: rook-ceph
spec:
  store: harbor-rgw
  displayName: "Harbor S3 User"
EOF

echo "Waiting for CephObjectStore to reach Ready phase..."
kubectl wait --for=jsonpath='{.status.phase}=Ready' -n rook-ceph cephobjectstore/harbor-rgw --timeout=10m
kubectl wait --for=object/secret=rook-ceph-object-user-harbor-rgw-harbor-user -n rook-ceph --timeout=10m

accesskey=$(kubectl -n rook-ceph get secret rook-ceph-object-user-harbor-rgw-harbor-user -o jsonpath='{.data.AccessKey}' | base64 -d)
secretkey=$(kubectl -n rook-ceph get secret rook-ceph-object-user-harbor-rgw-harbor-user -o jsonpath='{.data.SecretKey}' | base64 -d)

echo "Access Key: $accesskey"
echo "Secret Key: $secretkey"

helm upgrade --install harbor ./harbor-1.18.1.tgz --namespace harbor --wait --timeout 15m -f values.yaml \
  --set persistence.imageChartStorage.s3.accesskey="$accesskey" \
  --set persistence.imageChartStorage.s3.secretkey="$secretkey"