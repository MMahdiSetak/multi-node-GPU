CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm -f cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

cilium install --version 1.17.2
cilium status --wait
cilium connectivity test


#### modifications:

kubectl edit configmap cilium-config -n kube-system

#enable-node-port: "true"
enable-l2-announcements: "true"
kube-proxy-replacement: "true"
k8s-client-qps: "200"
k8s-client-burst: "300"

# for istio compatibility:
cni-exclusive: "false"
bpf-lb-sock-hostns-only: "true"
# socketLB.hostNamespaceOnly: "true"


# routing-mode: "native"
# tunnel-protocol: "" # vxlan 
# ipv4-native-routing-cidr: "10.0.0.0/8"  # Your cluster-pool-ipv4-cidr
# auto-direct-node-routes: "true"



kubectl -n kube-system rollout restart ds cilium
kubectl rollout restart deployment -n kube-system cilium-operator