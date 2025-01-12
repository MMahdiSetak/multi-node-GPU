bash all.sh

hostnamectl set-hostname master

firewall-cmd --permanent --add-port={6443,2379,2380,10250,10251,10252,10257,10259,179}/tcp
firewall-cmd --permanent --add-port=4789/udp
firewall-cmd --reload

sudo reboot

sudo kubeadm init --kubernetes-version=v1.32.0 --control-plane-endpoint=master
####### save this information #######
You can now join any number of control-plane nodes by copying certificate authorities
and service account keys on each node and then running the following as root:

kubeadm join master:6443 --token aot61h.ni1j9wpjdx8m8umc \
    --discovery-token-ca-cert-hash sha256:7fb206b4d47aa48e4a76fc0ef9ca338f2911fe1e759fef466a40db9b9feb23d1 \
    --control-plane

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join master:6443 --token aot61h.ni1j9wpjdx8m8umc \
    --discovery-token-ca-cert-hash sha256:7fb206b4d47aa48e4a76fc0ef9ca338f2911fe1e759fef466a40db9b9feb23d1
#####################################

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

cilium install --version 1.16.5

cilium status --wait

# If needed
sudo systemctl restart kubelet
sudo systemctl restart containerd

kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.30/deploy/local-path-storage.yaml
kubectl patch storageclass local-path \
    -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.17.0/deployments/static/nvidia-device-plugin.yml

cd ../manifests
while ! kubectl kustomize build example | kubectl apply -f -; do
    echo "Retrying to apply resources"
    sleep 20
done

kubectl port-forward --address 0.0.0.0 svc/istio-ingressgateway -n istio-system 8080:80
# Done!
# navigate to http://localhost:8080 user@example.com 12341234
