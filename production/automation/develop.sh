ssh-keygen -t rsa
ssh-copy-id admin@172.16.30.22
ssh-copy-id admin@172.16.30.23

sudo visudo
admin ALL=(ALL) NOPASSWD: ALL

# install ansible
VENVDIR=kubespray-venv
KUBESPRAYDIR=kubespray
python3 -m venv $VENVDIR
source $VENVDIR/bin/activate
cd $KUBESPRAYDIR
pip install -r requirements.txt



ansible -i inventory/mycluster/inventory.ini all -m ping

ansible-playbook -i inventory/mycluster/inventory.ini cluster.yml --check

ansible-playbook -i inventory/mycluster/inventory.ini cluster.yml -b -v
ansible-playbook -i inventory/mycluster/inventory.ini cluster.yml --tags network -b -v
ansible-playbook -i inventory/mycluster/inventory.ini reset.yml --become --become-user=root

# Offline install
cd contrib/offline
./generate_list.sh -i ../../inventory/mycluster/inventory.ini
./manage-offline-files.sh

export IMAGES_FROM_FILE=temp/images.list
./manage-offline-container-images.sh create

export DESTINATION_REGISTRY=worker-g02:5000
./manage-offline-container-images.sh register


sudo --preserve-env=http_proxy,https_proxy,no_proxy docker run \
        --restart=always -d -p 8080:80 \
        --volume ./offline-files:/usr/share/nginx/html/download \
        --volume ./nginx.conf:/etc/nginx/nginx.conf \
        --name nginx nginx:alpine

