sudo dnf update -y && sudo dnf upgrade -y
sudo dnf install -y epel-release
sudo dnf install -y dkms kernel-devel-$(uname -r)
sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo
sudo dnf module reset nvidia-driver
sudo dnf module enable nvidia-driver:565-dkms
sudo dnf module install -y nvidia-driver
sudo reboot

#sudo dnf module remove nvidia-driver
