sudo dnf update && sudo dnf upgrade -y
sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo
sudo dnf module reset nvidia-driver
sudo dnf module enable nvidia-driver:565-dkms
sudo dnf module install nvidia-driver
sudo reboot
