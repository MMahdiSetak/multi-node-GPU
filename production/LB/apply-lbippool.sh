#!/usr/bin/env bash
set -euo pipefail

# Load configuration
CONFIG_FILE="${CONFIG_FILE:-./config.env}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: Config file not found: $CONFIG_FILE" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

# ────────────────────────────────────────────────────────────────────────────────
#  Build IP Pool
# ────────────────────────────────────────────────────────────────────────────────
cat <<EOF | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumLoadBalancerIPPool
metadata:
  name: ${POOL_NAME}
spec:
  blocks:
  - start: "${START_IP}"
    stop: "${STOP_IP}"
EOF

echo ""
echo "Applied IP Pool: ${POOL_NAME}"
kubectl get ippools "${POOL_NAME}" -o wide || true
echo ""

# ────────────────────────────────────────────────────────────────────────────────
#  Build L2 Announcement Policy
# ────────────────────────────────────────────────────────────────────────────────

# Build interfaces array for YAML
# INTERFACES_YAML=""
# for intf in "${INTERFACES[@]}"; do
#   INTERFACES_YAML="${INTERFACES_YAML}  - ${intf}\n"
# done

# Build service selector (if any)
SERVICE_SELECTOR_YAML=""
if [[ ${#SERVICE_SELECTOR_MATCH_LABELS[@]} -gt 0 ]]; then
  SERVICE_SELECTOR_YAML="  serviceSelector:\n    matchLabels:\n"
  for label in "${SERVICE_SELECTOR_MATCH_LABELS[@]}"; do
    SERVICE_SELECTOR_YAML="${SERVICE_SELECTOR_YAML}      ${label}\n"
  done
fi

# Build node selector expressions (if any)
NODE_SELECTOR_YAML=""
if [[ ${#NODE_SELECTOR_MATCH_EXPRESSIONS[@]} -gt 0 ]]; then
  NODE_SELECTOR_YAML="  nodeSelector:\n    matchExpressions:\n"
  i=0
  while [[ $i -lt ${#NODE_SELECTOR_MATCH_EXPRESSIONS[@]} ]]; do
    key="${NODE_SELECTOR_MATCH_EXPRESSIONS[$i]}"
    op="${NODE_SELECTOR_MATCH_EXPRESSIONS[$((i+1))]}"
    NODE_SELECTOR_YAML="${NODE_SELECTOR_YAML}      - key: ${key}\n"
    NODE_SELECTOR_YAML="${NODE_SELECTOR_YAML}        operator: ${op}\n"
    ((i+=2))
  done
fi

# cat <<EOF | kubectl apply -f -
# apiVersion: cilium.io/v2alpha1
# kind: CiliumL2AnnouncementPolicy
# metadata:
#   name: ${POLICY_NAME}
# spec:
# ${SERVICE_SELECTOR_YAML}${NODE_SELECTOR_YAML}  interfaces:
# ${INTERFACES_YAML}  externalIPs: ${ANNOUNCE_EXTERNAL_IPS}
#   loadBalancerIPs: ${ANNOUNCE_LOADBALANCER_IPS}
# EOF

cat <<EOF | kubectl apply -f -
apiVersion: cilium.io/v2alpha1
kind: CiliumL2AnnouncementPolicy
metadata:
  name: ${POLICY_NAME}
spec:
#   serviceSelector:
#     matchLabels:
#       color: blue
  nodeSelector:
    matchExpressions:
      - key: node-role.kubernetes.io/control-plane
        operator: DoesNotExist
  interfaces:
    - ${INTERFACE}
  externalIPs: ${ANNOUNCE_EXTERNAL_IPS}
  loadBalancerIPs: ${ANNOUNCE_LOADBALANCER_IPS}
EOF

echo "Applied L2 Announcement Policy: ${POLICY_NAME}"
echo ""
# kubectl get ciliuml2announcementpolicy ${POLICY_NAME} -o yaml | grep -A 10 "spec:" || true
kubectl get ciliuml2announcementpolicy ${POLICY_NAME} || true