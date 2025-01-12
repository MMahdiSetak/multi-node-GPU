curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo |
    sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

sudo yum install -y nvidia-container-toolkit

sudo nvidia-ctk runtime configure --runtime=docker --set-as-default
sudo systemctl restart docker

nvidia-ctk runtime configure --runtime=containerd --set-as-default
sudo systemctl restart containerd
