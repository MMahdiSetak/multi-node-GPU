bash all.sh

hostnamectl set-hostname worker-g01

# firewall-cmd --permanent --add-port={179,10250,30000-32767}/tcp
# firewall-cmd --permanent --add-port=4789/udp
# firewall-cmd --reload

reboot

# Use token saved from master
kubeadm join master:6443 --token aot61h.ni1j9wpjdx8m8umc \
    --discovery-token-ca-cert-hash sha256:7fb206b4d47aa48e4a76fc0ef9ca338f2911fe1e759fef466a40db9b9feb23d1

# sudo bash ../prerequisites/nvidia-container-toolkit.sh
