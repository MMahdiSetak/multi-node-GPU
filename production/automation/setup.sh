#!/bin/bash

INVENTORY="kubespray/inventory/gpu-cluster/inventory.ini"

# Ensure ssh key exists
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Generating SSH key..."
    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
fi

# Extract IPs from inventory
HOSTS=$(grep -oP 'ansible_host=\K[0-9.]+' $INVENTORY)

for HOST in $HOSTS; do
    echo "======================================"
    echo "Processing $HOST"
    echo "======================================"

    # Copy SSH key
    sshpass -p "$PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no $USER@$HOST

    # Add passwordless sudo
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $USER@$HOST "
        echo '$USER ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/$USER >/dev/null
        sudo chmod 440 /etc/sudoers.d/$USER
    "

    echo "Done with $HOST"
done

echo "Bootstrap completed successfully."

cd kubespray/contrib/offline
tar Cxzvf /usr/local offline-files/github.com/containerd/containerd/releases/download/v2.1.5/containerd-2.1.5-linux-amd64.tar.gz
tar Cxzvf . offline-files/github.com/containerd/nerdctl/releases/download/v2.1.6/nerdctl-2.1.6-linux-amd64.tar.gz
mv nerdctl /usr/local/bin/nerdctl
sudo ln -s /usr/local/bin/nerdctl /usr/bin/nerdctl
rm -f containerd-rootless-setuptool.sh containerd-rootless.sh
tar Cxzvf . offline-files/get.helm.sh/helm-v3.18.4-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm
rm -rf linux-amd64

cat <<EOF | sudo tee /usr/lib/systemd/system/containerd.service
# Copyright The containerd Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target dbus.service

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5

# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now containerd

sudo tee /etc/profile.d/localbin.sh <<EOF
# Add /usr/local/bin to PATH for all users
export PATH="/usr/local/bin:\$PATH"
EOF
sudo chmod +x /etc/profile.d/localbin.sh
source /etc/profile.d/localbin.sh

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd

cd kubespray/contrib/offline
export DESTINATION_REGISTRY=$REGISTRY
sudo -E ./manage-offline-container-images.sh register

sudo nerdctl load -i container-images/docker.io-library-nginx-1.28.0-alpine.tar
set +e
sudo nerdctl container inspect nginx >/dev/null 2>&1
if [ $? -ne 0 ]; then
    sudo nerdctl run \
    --restart=always -d -p 8080:80 \
    --volume ./offline-files:/usr/share/nginx/html/download \
    --volume ./nginx.conf:/etc/nginx/nginx.conf \
    --name nginx nginx:1.28.0-alpine
fi
set -e

