#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd kubespray

ansible-playbook -i inventory/gpu-cluster/inventory.ini reset.yml -b -v \
    -e reset_confirmation=true | tee reset.log

ansible-playbook -i inventory/gpu-cluster/inventory.ini playbooks/prep_disks.yml -b -v