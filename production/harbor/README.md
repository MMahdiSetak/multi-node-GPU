### Endpoints to Create in Harbor

In the Harbor UI, go to **Administration** > **Registries** > **+ New Endpoint**. Use the details below for each. These cover all unique registries from your image list (e.g., docker.io for implicit/no-prefix images like mysql, nginx, openebs, goharbor, grafana; ghcr.io for kubeflow and kserve; etc.). No credentials are needed for public access—leave Access ID/Secret blank unless you have private repos.

| Endpoint Name | Provider | Endpoint URL |
|---------------|----------|--------------|
| docker-hub-upstream | Docker Hub | https://registry-1.docker.io |
| quay-upstream | Docker Registry | https://quay.io |
| nvcr-upstream | Docker Registry | https://nvcr.io |
| k8s-registry-upstream | Docker Registry | https://registry.k8s.io |
| ghcr-upstream | Docker Registry | https://ghcr.io |
| gcr-upstream | Google GCR | https://gcr.io |
| ecr-public-upstream | Docker Registry | https://public.ecr.aws |

After creating, test connectivity by clicking **Test Connection** in the UI.

### Proxy Cache Projects to Create in Harbor

Go to **Projects** > **+ New Project**. Set each to **Proxy Cache** type and link to the corresponding endpoint. Make them public for cluster-wide access without auth (or add auth if needed). These act as pull-through caches.

| Project Name | Access Level | Project Type | Linked Registry |
|--------------|--------------|--------------|-----------------|
| docker-hub-cache | Public | Proxy Cache | docker-hub-upstream |
| quay-cache | Public | Proxy Cache | quay-upstream |
| nvcr-cache | Public | Proxy Cache | nvcr-upstream |
| k8s-registry-cache | Public | Proxy Cache | k8s-registry-upstream |
| ghcr-cache | Public | Proxy Cache | ghcr-upstream |
| gcr-cache | Public | Proxy Cache | gcr-upstream |
| ecr-public-cache | Public | Proxy Cache | ecr-public-upstream |

### Containerd Configuration for Primary Use of Local Harbor

Edit `/etc/containerd/config.toml` on each node (generate default if missing: `containerd config default > /etc/containerd/config.toml`). Add the mirrors under `[plugins."io.containerd.grpc.v1.cri".registry.mirrors]` to redirect pulls to Harbor first (no manifest changes needed). Replace `your-harbor-domain` with your Harbor hostname/IP (e.g., 172.16.30.106). Since you have self-signed certs, add the TLS skip-verify section.

This prioritizes Harbor; if uncached, it falls back to upstream (implicit containerd behavior). For full air-gapping, pre-cache images and block internet.

```
[plugins."io.containerd.grpc.v1.cri".registry.mirrors]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
    endpoint = ["https://your-harbor-domain/v2/docker-hub-cache"]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."quay.io"]
    endpoint = ["https://your-harbor-domain/v2/quay-cache"]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."nvcr.io"]
    endpoint = ["https://your-harbor-domain/v2/nvcr-cache"]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.k8s.io"]
    endpoint = ["https://your-harbor-domain/v2/k8s-registry-cache"]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."ghcr.io"]
    endpoint = ["https://your-harbor-domain/v2/ghcr-cache"]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."gcr.io"]
    endpoint = ["https://your-harbor-domain/v2/gcr-cache"]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."public.ecr.aws"]
    endpoint = ["https://your-harbor-domain/v2/ecr-public-cache"]

[plugins."io.containerd.grpc.v1.cri".registry.configs]
  [plugins."io.containerd.grpc.v1.cri".registry.configs."your-harbor-domain".tls]
    insecure_skip_verify = true
```

Apply: `sudo systemctl restart containerd` on each node. Test: `crictl pull nginx` (should hit Harbor/docker-hub-cache). Pre-cache your images by pulling them via the proxy paths (e.g., `crictl pull your-harbor-domain/docker-hub-cache/library/nginx:latest`).

---

### Object Store (RGW) vs CephFS RWX – Which is Better for Production Harbor?

**RGW (S3-compatible Object Storage) is significantly better** for almost every production Harbor use case, especially yours (proxy cache + potential cluster migration/air-gap transfer).

| Aspect                  | Ceph RGW (S3)                                      | CephFS RWX                                          |
|-------------------------|----------------------------------------------------|-----------------------------------------------------|
| Registry HA (multi-replica) | Full support – you can run 3–10+ registry replicas safely | Only works with single replica or heavy locking overhead |
| Performance under load  | Excellent – native object storage, no metadata server bottleneck | Poor on concurrent pushes (metadata server becomes bottleneck) |
| Scalability             | Virtually unlimited                                  | Limited by CephFS metadata server performance       |
| Backup / Portability    | Extremely easy – `rclone sync` the bucket → portable directory → sync to new cluster | Hard – requires CephFS snapshots + volume restore or rsync with locks |
| Air-gapped migration    | Best option – bucket is just objects, syncable offline | Very difficult without identical CephFS setup       |
| Community / Official Rec | Harbor officially recommends S3 for production HA  | Only tolerated as a workaround                      |

**Verdict: **Use RGW**. CephFS RWX is only acceptable if you have a tiny deployment and already run CephFS for other reasons. For proxy caching (which can have bursty high traffic), RGW wins by a mile.

### Proxy Cache + Air-Gapped Transfer – Yes, Fully Possible (and RGW Makes It Easy)

You can absolutely use Harbor as a high-performance pull-through proxy cache and then move **all cached images** to an air-gapped cluster. There are two main strategies – choose based on how "complete" you want the transfer to be.

#### Option 1 – Recommended: Full Registry-Level Transfer via RGW Bucket Sync (Simplest & Most Complete)
Since you're using RGW, the entire image storage is just an S3 bucket.

1. On the **connected cluster**, let Harbor cache everything you need (create proxy projects → pull images → they get cached permanently).
2. Sync the bucket to a portable storage:
   ```bash
   # Install rclone once
   curl https://rclone.org/install.sh | sudo bash

   # Configure rclone for your RGW (one-time)
   rclone config create harbor-rgw s3 provider= Ceph access_key_id=<ACCESS_KEY> secret_access_key=<SECRET_KEY> endpoint=http://rook-ceph-rgw-harbor-rgw.rook-ceph.svc.cluster.local

   # Sync entire bucket to a portable drive (e.g., external SSD)
   rclone sync harbor-rgw:harbor-storage /mnt/external-drive/harbor-backup --progress
   ```
   This gives you every blob, manifest, and layer that Harbor ever cached (deduplicated, very efficient).

3. Take the drive to the **air-gapped cluster**.
4. On the air-gapped cluster, create the same RGW + bucket (same name `harbor-storage`), same CephObjectStoreUser credentials.
5. Sync back:
   ```bash
   rclone sync /mnt/external-drive/harbor-backup harbor-rgw-airgap:harbor-storage --progress
   ```

6. Install Harbor on the air-gapped cluster pointing to this RGW (same `values.yaml` storage section).  
   → All previously cached images are instantly available. No re-pull needed.

Bonus: You can also dump the PostgreSQL database (`pg_dumpall`) and restore it on the air-gapped cluster to keep projects, tags, users, replication rules, scan results, etc. Everything will look exactly the same.

This is the cleanest, fastest, and most production-grade method.

#### Option 2 – Image-by-Image Transfer (if you don't want to move the full registry state)
Use `regctl` or `skopeo` on an intermediate machine that can reach the connected Harbor.

```bash
# Install regctl (recommended, very fast)
curl -L https://github.com/regclient/regclient/releases/latest/download/regctl-linux-amd64 -o regctl
chmod +x regctl

# List everything in Harbor (requires admin token)
curl -u admin:HARBOR_ADMIN_PASSWORD -k https://harbor.yourdomain.com/api/v2.0/projects

# Script to copy every repository (example for one project)
for repo in $(curl -s -u admin:PASSWORD -k https://harbor.connected.local/api/v2.0/projects/myproject/repositories | jq -r '.[].name'); do
  for tag in $(curl -s -u admin:PASSWORD -k https://harbor.connected.local/api/v2.0/projects/myproject/repositories/${repo}/artifacts | jq -r '.[].tags[].name'); do
    regctl image copy harbor.connected.local/${repo}:${tag} harbor.airgap.local/${repo}:${tag}
  done
done
```

For true air-gap, replace the final copy with OCI directory:
```bash
regctl image copy harbor.connected.local/library/ubuntu:latest oci:/tmp/ubuntu
# → transfers to portable directory, then on air-gapped side:
regctl image copy oci:/tmp/ubuntu harbor.airgap.local/library/ubuntu:latest
```

This works perfectly but is slower than RGW sync for very large caches.

### Local Network Access Without Valid TLS (http + Fixed IP 172.16.30.110)

Use this updated `harbor-values.yaml` snippet (replace the relevant sections from my previous guide):

```yaml
externalURL: http://172.16.30.110   # ← important, no https

expose:
  type: loadBalancer                 # best with Cilium L2
  tls:
    enabled: false                   # no TLS at all
  loadBalancer:
    IP: 172.16.30.110                # static VIP (works if your cluster supports it)
    annotations:
      io.cilium/lb-ipam-ips: "172.16.30.110"   # Cilium IPAM – keeps the IP fixed
      io.cilium/lb-ipam-sharing-key: "harbor       # optional – groups multiple services
  ingress: {}                        # leave empty – we don't use ingress

# Keep internalTLS if you want (recommended for security even on local net)
internalTLS:
  enabled: true                      # components still talk TLS internally (uses self-signed truststore)

# If you prefer NodePort instead (also works great):
```yaml
expose:
  type: nodePort
  nodePort:
    ports:
      http: 30080   # access via http://172.16.30.110:30080
      https: 30443  # disabled anyway
  tls:
    enabled: false
```

After `helm upgrade --install`, you access Harbor at `http://172.16.30.110` (or with port if NodePort).

Cilium will ARP-announce 172.16.30.110 for the LoadBalancer service → every machine on the local network can reach Harbor directly by IP, no DNS needed.

This setup is perfect for internal/air-gapped use – fast, simple, secure enough for local network (you still have basic auth + can enable internalTLS).

Let me know which transfer method you prefer or if you want the full updated `values.yaml` – happy to send the complete file.