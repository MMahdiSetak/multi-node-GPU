REGISTRY="worker-g02:5000"

cat << EOF | helm upgrade --install harbor-db ../pg/postgresql-18.2.0.tgz -n harbor --create-namespace --values -
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
kubectl wait --for=jsonpath='{.status.phase}=Ready' -n rook-ceph CephObjectStoreUser/harbor-user --timeout=10m
# kubectl wait --for=object/secret=rook-ceph-object-user-harbor-rgw-harbor-user -n rook-ceph --timeout=10m

accesskey=$(kubectl -n rook-ceph get secret rook-ceph-object-user-harbor-rgw-harbor-user -o jsonpath='{.data.AccessKey}' | base64 -d)
secretkey=$(kubectl -n rook-ceph get secret rook-ceph-object-user-harbor-rgw-harbor-user -o jsonpath='{.data.SecretKey}' | base64 -d)

echo "Access Key: $accesskey"
echo "Secret Key: $secretkey"
# TODO variable for proxy
helm upgrade --install harbor ./harbor-1.18.1.tgz --namespace harbor --wait --timeout 15m -f values.yaml \
  --set persistence.imageChartStorage.s3.accesskey="$accesskey" \
  --set persistence.imageChartStorage.s3.secretkey="$secretkey" \
  --set nginx.image.repository="${REGISTRY}/goharbor/nginx-photon" \
  --set portal.image.repository="${REGISTRY}/goharbor/harbor-portal" \
  --set core.image.repository="${REGISTRY}/goharbor/harbor-core" \
  --set jobservice.image.repository="${REGISTRY}/goharbor/harbor-jobservice" \
  --set registry.registry.image.repository="${REGISTRY}/goharbor/registry-photon" \
  --set registry.controller.image.repository="${REGISTRY}/goharbor/harbor-registryctl" \
  --set trivy.image.repository="${REGISTRY}/goharbor/trivy-adapter-photon" \
  --set exporter.image.repository="${REGISTRY}/goharbor/harbor-exporter"

# TODO create bucket harbor-storage
# sleep 5000 # TODO change with wait till ready state

curl -sk -u "admin:Harbor12345" -X POST "https://172.16.30.202/api/v2.0/registries" \
    -H "Content-Type: application/json" -d "{\"url\": \"https://registry-1.docker.io\", \"name\": \"docker-hub-upstream\", \"type\": \"docker-hub\"}"
curl -sk -u "admin:Harbor12345" -X POST "https://172.16.30.202/api/v2.0/registries" \
    -H "Content-Type: application/json" -d "{\"url\": \"https://quay.io\", \"name\": \"quay-upstream\", \"type\": \"docker-registry\"}"
curl -sk -u "admin:Harbor12345" -X POST "https://172.16.30.202/api/v2.0/registries" \
    -H "Content-Type: application/json" -d "{\"url\": \"https://nvcr.io\", \"name\": \"nvcr-upstream\", \"type\": \"docker-registry\"}"
curl -sk -u "admin:Harbor12345" -X POST "https://172.16.30.202/api/v2.0/registries" \
    -H "Content-Type: application/json" -d "{\"url\": \"https://registry.k8s.io\", \"name\": \"k8s-registry-upstream\", \"type\": \"docker-registry\"}"
curl -sk -u "admin:Harbor12345" -X POST "https://172.16.30.202/api/v2.0/registries" \
    -H "Content-Type: application/json" -d "{\"url\": \"https://ghcr.io\", \"name\": \"ghcr-upstream\", \"type\": \"docker-registry\"}"
curl -sk -u "admin:Harbor12345" -X POST "https://172.16.30.202/api/v2.0/registries" \
    -H "Content-Type: application/json" -d "{\"url\": \"https://gcr.io\", \"name\": \"gcr-upstream\", \"type\": \"docker-registry\"}"
curl -sk -u "admin:Harbor12345" -X POST "https://172.16.30.202/api/v2.0/registries" \
    -H "Content-Type: application/json" -d "{\"url\": \"https://public.ecr.aws\", \"name\": \"ecr-public-upstream\", \"type\": \"docker-registry\"}"


id=$(curl -sk -u "admin:Harbor12345" "https://172.16.30.202/api/v2.0/registries" | grep -o '"id":[0-9]*,"name":"docker-hub-upstream"' | cut -d, -f1 | cut -d: -f2)
curl -sk -u "admin:Harbor12345" -X POST "https://172.16.30.202/api/v2.0/projects" \
    -H "Content-Type: application/json" -d "{\"project_name\": \"docker-hub-cache\", \"public\": true, \"registry_id\": $id}"
id=$(curl -sk -u "admin:Harbor12345" "https://172.16.30.202/api/v2.0/registries" | grep -o '"id":[0-9]*,"name":"quay-upstream"' | cut -d, -f1 | cut -d: -f2)
curl -sk -u "admin:Harbor12345" -X POST "https://172.16.30.202/api/v2.0/projects" \
    -H "Content-Type: application/json" -d "{\"project_name\": \"quay-cache\", \"public\": true, \"registry_id\": $id}"
id=$(curl -sk -u "admin:Harbor12345" "https://172.16.30.202/api/v2.0/registries" | grep -o '"id":[0-9]*,"name":"nvcr-upstream"' | cut -d, -f1 | cut -d: -f2)
curl -sk -u "admin:Harbor12345" -X POST "https://172.16.30.202/api/v2.0/projects" \
    -H "Content-Type: application/json" -d "{\"project_name\": \"nvcr-cache\", \"public\": true, \"registry_id\": $id}"
id=$(curl -sk -u "admin:Harbor12345" "https://172.16.30.202/api/v2.0/registries" | grep -o '"id":[0-9]*,"name":"k8s-registry-upstream"' | cut -d, -f1 | cut -d: -f2)
curl -sk -u "admin:Harbor12345" -X POST "https://172.16.30.202/api/v2.0/projects" \
    -H "Content-Type: application/json" -d "{\"project_name\": \"k8s-registry-cache\", \"public\": true, \"registry_id\": $id}"
id=$(curl -sk -u "admin:Harbor12345" "https://172.16.30.202/api/v2.0/registries" | grep -o '"id":[0-9]*,"name":"ghcr-upstream"' | cut -d, -f1 | cut -d: -f2)
curl -sk -u "admin:Harbor12345" -X POST "https://172.16.30.202/api/v2.0/projects" \
    -H "Content-Type: application/json" -d "{\"project_name\": \"ghcr-cache\", \"public\": true, \"registry_id\": $id}"
id=$(curl -sk -u "admin:Harbor12345" "https://172.16.30.202/api/v2.0/registries" | grep -o '"id":[0-9]*,"name":"gcr-upstream"' | cut -d, -f1 | cut -d: -f2)
curl -sk -u "admin:Harbor12345" -X POST "https://172.16.30.202/api/v2.0/projects" \
    -H "Content-Type: application/json" -d "{\"project_name\": \"gcr-cache\", \"public\": true, \"registry_id\": $id}"
id=$(curl -sk -u "admin:Harbor12345" "https://172.16.30.202/api/v2.0/registries" | grep -o '"id":[0-9]*,"name":"ecr-public-upstream"' | cut -d, -f1 | cut -d: -f2)
curl -sk -u "admin:Harbor12345" -X POST "https://172.16.30.202/api/v2.0/projects" \
    -H "Content-Type: application/json" -d "{\"project_name\": \"ecr-public-cache\", \"public\": true, \"registry_id\": $id}"
