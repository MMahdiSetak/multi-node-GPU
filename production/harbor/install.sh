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

accesskey=$(kubectl -n rook-ceph get secret rook-ceph-object-user-harbor-rgw-harbor-user -o jsonpath='{.data.AccessKey}' | base64 -d)
secretkey=$(kubectl -n rook-ceph get secret rook-ceph-object-user-harbor-rgw-harbor-user -o jsonpath='{.data.SecretKey}' | base64 -d)

echo "Access Key: $accesskey"
echo "Secret Key: $secretkey"

cat << EOF | helm install harbor-db ./postgresql-18.2.0.tgz -n harbor --create-namespace --values -
auth:
  username: harbor
  password: VeryStrongPostgresPass123
  database: registry
  postgresPassword: AnotherVeryStrongPostgresPass123   # optional but good to set

primary:
  persistence:
    enabled: true
    storageClass: rook-ceph-block
    size: 50Gi
  resources:
    requests:
      memory: 512Mi
      cpu: 500m
    limits:
      memory: 2Gi
      cpu: 2000m

readReplicas:
  replicaCount: 2
  persistence:
    enabled: true
    storageClass: rook-ceph-block
    size: 50Gi
  resources:
    requests:
      memory: 512Mi
      cpu: 500m
    limits:
      memory: 2Gi
      cpu: 2000m   # optional, but recommended

volumePermissions:
  enabled: true
EOF

helm install harbor-redis ./redis-24.1.0.tgz -n harbor \
  --set auth.password='VeryStrongRedisPass123' \
  --set architecture=replication \
  --set master.persistence.enabled=true \
  --set master.persistence.storageClass=rook-ceph-block \
  --set master.persistence.size=20Gi \
  --set replica.replicaCount=3 \
  --set replica.persistence.enabled=true \
  --set replica.persistence.storageClass=rook-ceph-block \
  --set replica.persistence.size=20Gi

helm upgrade --install harbor ./harbor-1.18.1.tgz --namespace harbor --wait --timeout 15m -f values.yaml