ssh-keygen -t rsa
ssh-copy-id admin@172.16.30.22
ssh-copy-id admin@172.16.30.23
ssh-copy-id admin@172.16.30.26

sudo visudo
admin ALL=(ALL) NOPASSWD: ALL

# install ansible
VENVDIR=kubespray-venv
KUBESPRAYDIR=kubespray
python3.12 -m venv $VENVDIR
source $VENVDIR/bin/activate
cd $KUBESPRAYDIR
pip install -r requirements.txt



ansible -i inventory/gpu-cluster/inventory.ini all -m ping

# ansible-playbook -i inventory/mycluster/inventory.ini cluster.yml --check

# ansible-playbook -i inventory/gpu-cluster/inventory.ini cluster.yml -b -v \
#     --skip-tags=apps,metrics_server,ingress_nginx,helm,bootstrap-os.swap,bootstrap-os.packages | tee deploy.log

ansible-playbook -i inventory/gpu-cluster/inventory.ini cluster.yml -b -v \
    --skip-tags=metrics_server,ingress_nginx,helm,bootstrap-os.swap,bootstrap-os.packages | tee deploy.log

ansible-playbook -i inventory/gpu-cluster/inventory.ini scale.yml -b -v \
    --skip-tags=metrics_server,ingress_nginx,helm,bootstrap-os.swap,bootstrap-os.packages | tee scale.log

ansible master -i inventory/gpu-cluster/inventory.ini -b --become-user=root \
  -m fetch \
  -a "src=/etc/kubernetes/admin.conf dest=~/.kube/config flat=yes"
MASTER_IP=$(ansible -i inventory/gpu-cluster/inventory.ini kube_control_plane \
  -m debug -a "msg={{ ansible_host | default(inventory_hostname) }}" \
  | grep msg | awk -F'"' '{print $4}')
echo "Master IP is: $MASTER_IP"
sed -i "s|127.0.0.1|${MASTER_IP}|g" ~/.kube/config


ansible-playbook -i inventory/gpu-cluster/inventory.ini cluster.yml --tags network -b -v

sudo sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/kubernetes.repo
ansible-playbook -i inventory/gpu-cluster/inventory.ini reset.yml -b -v \
    -e reset_confirmation=true | tee reset.log

# Offline install
cd contrib/offline
./generate_list.sh -i ../../inventory/gpu-cluster/inventory.ini
./manage-offline-files.sh
nerdctl run \
    --restart=always -d -p 8080:80 \
    --volume ./offline-files:/usr/share/nginx/html/download \
    --volume ./nginx.conf:/etc/nginx/nginx.conf \
    --name nginx nginx:alpine

export IMAGES_FROM_FILE=temp/images.list
./manage-offline-container-images.sh create

export DESTINATION_REGISTRY=worker-g02:5000
./manage-offline-container-images.sh register


# Wipe all signatures (Ceph, LVM, filesystem, etc.)
wipefs -a -f /dev/sdq

# Zap GPT/MBR partition tables
sgdisk --zap-all /dev/sdq


ansible-playbook -i inventory/gpu-cluster/inventory.ini playbooks/prep_disks.yml -b -v --check | tee prep_disk.log

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$ROOT_DIR/env/global.env"

bash "$ROOT_DIR/LB/apply-lbippool.sh"
bash "$ROOT_DIR/csi/rook-ceph/install.sh"
bash "$ROOT_DIR/harbor/install.sh"
bash "$ROOT_DIR/monitor/install.sh"
bash "$ROOT_DIR/kubeflow/install.sh"