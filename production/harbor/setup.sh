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

helm uninstall harbor -n harbor
kubectl delete pvc harbor-jobservice -n harbor

helm upgrade --install harbor harbor/harbor --namespace harbor --wait --timeout 15m -f values.yaml

kubectl delete ns harbor

Harbor12345


kubectl get pods,deployments,daemonsets,replicasets,statefulsets,jobs,cronjobs --all-namespaces -o jsonpath="{.items[*].spec.template.spec.containers[*].image} {.items[*].spec.template.spec.initContainers[*].image} {.items[*].spec.jobTemplate.spec.template.spec.containers[*].image} {.items[*].spec.jobTemplate.spec.template.spec.initContainers[*].image}" | tr -s '[[:space:]]' '\n' | sort | uniq -c | sort -nr

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-large-pull-pod
spec:
  nodeName: worker-g02
  containers:
  - name: test-container
    image: ghcr.io/kubeflow/kubeflow/notebook-servers/jupyter-pytorch-cuda-full:v1.10.0
    # image: oasislabs/testing:hello-world-1gb
    # image: pytorch/pytorch:2.9.1-cuda12.6-cudnn9-runtime
    # image: docker.io/library/python
    # image: harbor:443/docker-hub-cache/oasislabs/testing:hello-world-1gb # 200
    # image: 172.16.30.106/docker-hub-cache/oasislabs/testing:hello-world-1gb # 509
    command: ["sleep", "infinity"]
    resources:
      limits:
        cpu: "100m"
        memory: "128Mi"
  restartPolicy: Never
EOF
kubectl delete pod test-large-pull-pod

ctr images pull --local --skip-verify --hosts-dir "/etc/containerd/certs.d" docker.io/oasislabs/testing:hello-world-1gb
ctr images pull --local --skip-verify 172.16.30.106/docker-hub-cache/oasislabs/testing:hello-world-1gb

docker pull 172.16.30.106/docker-hub-cache/oasislabs/testing:hello-world-1gb
docker pull harbor/docker-hub-cache/oasislabs/testing:hello-world-1gb

curl -v -k -u admin:Harbor12345 https://172.16.30.106/docker-hub-cache/oasislabs/testing:hello-world-1gb

curl -v -k -u admin:Harbor12345 https://172.16.30.106/v2/docker-hub-cache/oasislabs/testing/manifests/hello-world-1gb
ctr image pull --hosts-dir "/etc/containerd/certs.d" --user admin:Harbor12345 docker.io/oasislabs/testing:hello-world-1gb


crictl rmi --prune
crictl pull 172.16.30.106/docker-hub-cache/oasislabs/testing:hello-world-1gb

/etc/pki/ca-trust/source/anchors
update-ca-trust

crictl pull pytorch/pytorch:2.9.1-cuda12.6-cudnn9-runtime
crictl pull oasislabs/testing:hello-world-1gb
crictl pull harbor:443/docker-hub-cache/oasislabs/testing:hello-world-1gb
crictl pull harbor:443/k8s-registry-cache/kube-proxy:v1.33.5
crictl pull harbor:443/docker-hub-cache/registry.k8s.io/kube-proxy:v1.33.5

curl -v -k -u admin:Harbor12345 https://harbor/v2/docker-hub-cache/oasislabs/testing/manifests/hello-world-1gb


docker pull harbor/oasislabs/testing:hello-world-1gb

nerdctl --preserve-env=http_proxy,https_proxy,no_proxy pull registry.k8s.io/kube-proxy:v1.33.5
nerdctl pull harbor:443/docker-hub-cache/oasislabs/testing:hello-world-1gb
#tests:
nerdctl pull oasislabs/testing:hello-world-1gb
nerdctl pull quay.io/cilium/cilium:v1.18.2
nerdctl pull ghcr.io/jonashackt/hello-world:latest
nerdctl pull public.ecr.aws/aws-cli/aws-cli:latest
nerdctl pull gcr.io/distroless/base:latest
nerdctl pull nvcr.io/nvidia/cuda:12.0.0-base-ubuntu20.04
nerdctl pull registry.k8s.io/pause:3.9

nerdctl pull harbor:443/gcr-cache/distroless/base:latest
nerdctl pull harbor:443/nvcr-cache/nvidia/cuda:12.0.0-base-ubuntu20.04
nerdctl pull harbor:443/k8s-registry-cache/pause:3.9

nerdctl pull --insecure-registry 172.16.30.202/cache/oasislabs/testing:hello-world-1gb
nerdctl pull --insecure-registry 172.16.30.202/docker-hub-cache/library/python
nerdctl pull --insecure-registry 172.16.30.202/docker-hub-cache/goharbor/nginx-photon:v2.14.0
nerdctl pull --insecure-registry 172.16.30.202/quay-cache/cilium/cilium:v1.18.2
nerdctl pull --insecure-registry 172.16.30.202/ghcr-cache/jonashackt/hello-world:latest
nerdctl pull --insecure-registry 172.16.30.202/ecr-public-cache/aws-cli/aws-cli:latest
nerdctl pull --insecure-registry 172.16.30.202/gcr-cache/distroless/base:latest
nerdctl pull --insecure-registry 172.16.30.202/nvcr-cache/nvidia/cuda:12.0.0-base-ubuntu20.04
nerdctl pull --insecure-registry 172.16.30.202/k8s-registry-cache/pause:3.9
nerdctl pull --insecure-registry 172.16.30.202/k8s-registry-cache/kube-proxy:v1.33.7


nerdctl pull registry.k8s.io/pause:3.9

nerdctl pull registry.k8s.io/sig-storage/csi-resizer:v1.13.2
nerdctl pull --insecure-registry 172.16.30.202/k8s-registry-cache/sig-storage/csi-resizer:v1.13.2
crictl pull registry.k8s.io/sig-storage/csi-resizer:v1.13.2

nerdctl pull --insecure-registry 172.16.30.25:5000/ceph/ceph:v19.2.3
