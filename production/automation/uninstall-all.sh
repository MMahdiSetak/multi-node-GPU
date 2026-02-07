#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd $SCRIPT_DIR/kubespray

ansible-playbook -i inventory/gpu-cluster/inventory.ini reset.yml -b -v \
  -e reset_confirmation=true | tee reset.log

# ansible all -i inventory/gpu-cluster/inventory.ini -b -m command -a "/usr/local/bin/nerdctl system prune -af"

ansible-playbook -i inventory/gpu-cluster/inventory.ini playbooks/prep_disks.yml -b -v

ansible all -i inventory/gpu-cluster/inventory.ini -b -m shell -a '
  systemctl stop rook-ceph-mon@* || true
  rm -rf /var/lib/rook/rook-ceph/* /var/lib/rook/mon-* /var/lib/rook/*
  mkdir -p /var/lib/rook/rook-ceph
  chown -R ceph:ceph /var/lib/rook 2>/dev/null || true
'