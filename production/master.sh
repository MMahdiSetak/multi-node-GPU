bash all.sh
bash ../prerequisites/helm.sh

hostnamectl set-hostname master

# firewall-cmd --permanent --add-port={6443,2379,2380,10250,10251,10252,10257,10259,179}/tcp
# firewall-cmd --permanent --add-port=4789/udp
# firewall-cmd --reload

sudo reboot

sudo kubeadm init --kubernetes-version=v1.33.0 --control-plane-endpoint=master
####### save this information #######
#You can now join any number of control-plane nodes by copying certificate authorities
#and service account keys on each node and then running the following as root:
#
#kubeadm join master:6443 --token aot61h.ni1j9wpjdx8m8umc \
#    --discovery-token-ca-cert-hash sha256:7fb206b4d47aa48e4a76fc0ef9ca338f2911fe1e759fef466a40db9b9feb23d1 \
#    --control-plane
#
#Then you can join any number of worker nodes by running the following on each as root:
#
#kubeadm join master:6443 --token aot61h.ni1j9wpjdx8m8umc \
#    --discovery-token-ca-cert-hash sha256:7fb206b4d47aa48e4a76fc0ef9ca338f2911fe1e759fef466a40db9b9feb23d1
#####################################

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

bash cni/cilium.sh
bash csi/openebs.sh

# If needed
sudo systemctl restart kubelet
sudo systemctl restart containerd

# kubectl label node master node-role.kubernetes.io/control-plane=control-plane
kubectl label node worker-g01 node-role.kubernetes.io/worker=worker
# kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# Add kubernetes-dashboard repository
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
# Deploy a Helm Release named "kubernetes-dashboard" using the kubernetes-dashboard chart
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443


# kubectl label node worker-g01 nvidia.com/gpu=true
kubectl label node worker-g01 nvidia.com/gpu.present=true
# kubectl label node worker-g01 nvidia.com/mps.capable=true

bash ./monitoring/kube-prometheus.sh

bash ./GPU-operator.sh
# helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
# helm repo update
# helm upgrade -i nvdp nvdp/nvidia-device-plugin \
#     --namespace nvidia-device-plugin \
#     --create-namespace \
#     --version 0.17.0
# kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.17.0/deployments/static/nvidia-device-plugin.yml

curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo install -o root -g root -m 0755 kustomize /usr/local/bin/kustomize

docker login
kubectl create secret generic regcred \
    --from-file=.dockerconfigjson=/root/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson

bash ./kubeflow/kubeflow.sh
