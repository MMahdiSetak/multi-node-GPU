# Disable swap
sudo sed -i '/\sswap\s/s/^/#/' /etc/fstab
sudo swapoff -a

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config


# cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
# overlay
# br_netfilter
# EOF

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
fs.inotify.max_user_instances=2280
fs.inotify.max_user_watches=1255360
EOF
# Apply sysctl params without reboot
sudo sysctl --system

cat <<EOF | sudo tee -a /etc/hosts
192.168.20.73 master
192.168.20.74 worker-s01
192.168.20.139 worker-g01
EOF

sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo systemctl status firewalld

# sudo bash ../prerequisites/docker.sh
sudo bash ../prerequisites/containerd.sh
sudo bash ../prerequisites/kubernetes.sh