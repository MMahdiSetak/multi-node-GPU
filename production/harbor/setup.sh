cat <<EOF | kubectl apply -f -
apiVersion: ceph.rook.io/v1
kind: CephObjectStore
metadata:
  name: harbor-rgw
  namespace: rook-ceph   # change if your Rook is in different namespace
spec:
  metadataPool:
    replicated:
      size: 3
  dataPool:
    replicated:
      size: 3
  preservePoolsOnDelete: true
  gateway:
    instances: 2      # HA RGW pods
    port: 80         # use 443 + TLS if you want secure RGW
EOF

kubectl -n rook-ceph get cephobjectstore harbor-rgw -w

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


# Get credentials
kubectl -n rook-ceph get secret rook-ceph-object-user-harbor-rgw-harbor-user -o jsonpath='{.data.AccessKey}' | base64 -d
kubectl -n rook-ceph get secret rook-ceph-object-user-harbor-rgw-harbor-user -o jsonpath='{.data.SecretKey}' | base64 -d

JU650M21KDXTCGCHXIJW
q82W4iAyP5pHr3DEN4bSqDKY6AQLH9piDX3EcjMc

cat << EOF | helm install harbor-db bitnami/postgresql -n harbor --create-namespace --values -
auth:
  username: harbor
  password: VeryStrongPostgresPass123
  database: harbor
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

# Recommended for Rook/Ceph (fixes permission issues on some clusters)
volumePermissions:
  enabled: true
EOF


helm install harbor-redis bitnami/redis -n harbor \
  --set auth.password='VeryStrongRedisPass123' \
  --set architecture=replication \
  --set master.persistence.enabled=true \
  --set master.persistence.storageClass=rook-ceph-block \
  --set master.persistence.size=20Gi \
  --set replica.replicaCount=3 \
  --set replica.persistence.enabled=true \
  --set replica.persistence.storageClass=rook-ceph-block \
  --set replica.persistence.size=20Gi

helm repo add harbor https://helm.goharbor.io
helm repo update

cat <<EOF | helm upgrade --install harbor harbor/harbor --namespace harbor --wait --timeout 15m -f -
externalURL: http://172.16.30.106
harborAdminPassword: "VeryStrongAdminPass123!"
expose:
  type: loadBalancer
  tls:
    enabled: false
  loadBalancer:
    IP: 172.16.30.106
    annotations:
      io.cilium/lb-ipam-ips: "172.16.30.106"
      io.cilium/lb-ipam-sharing-key: "harbor"
  ingress: {}
internalTLS:
  enabled: false
persistence:
  enabled: true
  resourcePolicy: "keep"
  storageClass: rook-ceph-block
  persistentVolumeClaim:
    registry:
      size: 100Gi
    chartmuseum:
      size: 20Gi
    jobservice:
      jobLog:
        size: 2Gi
    trivy:
      size: 10Gi
imageChartStorage:
  type: s3
  s3:
    region: us-east-1
    regionendpoint: http://rook-ceph-rgw-harbor-rgw.rook-ceph.svc.cluster.local
    accesskey: "JU650M21KDXTCGCHXIJW"
    secretkey: "q82W4iAyP5pHr3DEN4bSqDKY6AQLH9piDX3EcjMc"
    bucket: harbor-storage
    secure: false
    v4auth: true
    chunksize: "10m"
database:
  type: external
  external:
    host: harbor-db-postgresql.harbor.svc.cluster.local
    port: 5432
    username: harbor
    password: VeryStrongPostgresPass123
    coreDatabase: harbor
    sslmode: disable
redis:
  type: external
  external:
    addr: harbor-redis-master.harbor.svc.cluster.local:6379
    password: VeryStrongRedisPass123
    database: 0
trivy:
  enabled: true
  replicas: 2
core:
  replicas: 2
portal:
  replicas: 2
jobservice:
  replicas: 3
registry:
  replicas: 3
nginx:
  replicas: 3
logLevel: info
EOF