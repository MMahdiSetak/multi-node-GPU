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
externalURL: https://harbor.yourdomain.com

harborAdminPassword: "VeryStrongAdminPass123!"

expose:
  type: loadBalancer                 # best with Cilium L2
    tls:
      enabled: false                   # no TLS at all
    loadBalancer:
      IP: 172.16.30.110                # static VIP (works if your cluster supports it)
      annotations:
        io.cilium/lb-ipam-ips: "172.16.30.110"   # Cilium IPAM keeps the IP fixed
        io.cilium/lb-ipam-sharing-key: "harbor       # optional groups multiple services
    ingress: {}                        # leave empty we don't use ingress

persistence:
  enabled: true
  resourcePolicy: keep
  storageClass: rook-ceph-block
  persistentVolumeClaim:
    registry:
      size: 1Ti          # adjust to your needs
    chartmuseum:
      size: 200Gi
    jobservice:
      jobLog:
        size: 20Gi
    trivy:
      size: 100Gi

imageChartStorage:
  type: s3
  s3:
    region: us-east-1
    regionendpoint: http://rook-ceph-rgw-harbor-rgw.rook-ceph.svc.cluster.local
    accesskey: "<YOUR_ACCESS_KEY_FROM_STEP_2>"
    secretkey: "<YOUR_SECRET_KEY_FROM_STEP_2>"
    bucket: harbor-storage
    secure: false      # set true + port 443 if you configured TLS on RGW
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
  replicas: 3        # safe because we use S3 storage
nginx:
  replicas: 3

internalTLS:
  enabled: true      # production recommendation – components communicate over TLS

logLevel: info
EOF