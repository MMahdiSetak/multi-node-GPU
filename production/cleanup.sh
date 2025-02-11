kubectl drain worker-s01 --ignore-daemonsets --delete-emptydir-data
kubectl delete node worker-s01

sudo kubeadm reset -f

sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -X

sudo rm -rf /etc/cni /opt/cni /var/lib/cni
sudo rm -rf /etc/kubernetes
sudo rm -rf /var/lib/etcd
sudo rm -rf $HOME/.kube

You can now join any number of control-plane nodes by copying certificate authorities
and service account keys on each node and then running the following as root:

kubeadm join master:6443 --token sempc9.ay113h7asaifyit9 \
	--discovery-token-ca-cert-hash sha256:a49ca4d29de47ba136fcac97f8da0cb15b218e6a381d2b50c491ec17572da259 \
	--control-plane

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join master:6443 --token sempc9.ay113h7asaifyit9 \
	--discovery-token-ca-cert-hash sha256:a49ca4d29de47ba136fcac97f8da0cb15b218e6a381d2b50c491ec17572da259

kubeadm token create
kubeadm token create --print-join-command

kubeadm join master:6443 --token 2zlbz7.vtaggkp2n6y6yewp \
	--discovery-token-ca-cert-hash sha256:a49ca4d29de47ba136fcac97f8da0cb15b218e6a381d2b50c491ec17572da259

# To access Dashboard run:
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443
# NOTE: In case port-forward command does not work, make sure that kong service name is correct.
#       Check the services in Kubernetes Dashboard namespace using:
kubectl -n kubernetes-dashboard get svc
# Dashboard will be available at:
# https://localhost:8443

scp /etc/kubernetes/admin.conf user01@192.168.20.77:~/.kube/config

#The CustomResourceDefinition "inferenceservices.serving.kserve.io" is invalid: spec.conversion.webhookClientConfig.caBundle: Invalid value: []byte{0xa}: unable to load root certificates: unable to parse bytes as PEM block
kubectl get crd inferenceservices.serving.kserve.io -o yaml | grep caBundle
kubectl delete crd inferenceservices.serving.kserve.io
# kubectl get crd inferenceservices.serving.kserve.io -o yaml | grep -A10 caBundle
# kubectl rollout restart deployment kserve-controller-manager -n kubeflow
# kubectl get crd inferenceservices.serving.kserve.io -o yaml | grep -A10 caBundle
