set -euo pipefail

cd kubespray

# ansible-playbook -i inventory/gpu-cluster/inventory.ini reset.yml -b -v \
#     -e reset_confirmation=true | tee reset.log

ansible all -i inventory/gpu-cluster/inventory.ini -b -m shell -a '
  systemctl stop rook-ceph-mon@* || true
  rm -rf /var/lib/rook/rook-ceph/* /var/lib/rook/mon-* /var/lib/rook/*
  mkdir -p /var/lib/rook/rook-ceph
  chown -R ceph:ceph /var/lib/rook 2>/dev/null || true
'

ansible-playbook -i inventory/gpu-cluster/inventory.ini cluster.yml -b -v \
    --skip-tags=metrics_server,ingress_nginx,helm,bootstrap-os.swap,bootstrap-os.packages | tee ../deploy.log

ansible master -i inventory/gpu-cluster/inventory.ini -b --become-user=root \
  -m fetch \
  -a "src=/etc/kubernetes/admin.conf dest=~/.kube/config flat=yes"
MASTER_IP=$(ansible -i inventory/gpu-cluster/inventory.ini kube_control_plane \
  -m debug -a "msg={{ ansible_host | default(inventory_hostname) }}" \
  | grep msg | awk -F'"' '{print $4}')
echo "Master IP is: $MASTER_IP"
sed -i "s|127.0.0.1|${MASTER_IP}|g" ~/.kube/config

kubectl taint node master node-role.kubernetes.io/control-plane:NoSchedule-

cd ../../LB
bash ./apply-lbippool.sh

cd ../csi/rook-ceph
bash ./install.sh

# bash ../monitoring/install.sh
# bash ../gpu-operator/install.sh
# bash ../kubeflow/install.sh