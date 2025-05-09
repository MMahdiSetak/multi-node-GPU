#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF >&2
Usage: $0 -u USERNAME -e EMAIL -m MASTER_IP [--dry-run]
  -u USERNAME   Kubernetes username & namespace suffix
  -e EMAIL      Email (also used as User CN in cert)
  -m MASTER_IP  API server IP (or DNS) for --server=https://<MASTER_IP>:6443
  --dry-run     Print manifests and kubeconfig steps without applying
EOF
  exit 1
}

# defaults
dryrun=false

# parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
  -u)
    username=$2
    shift 2
    ;;
  -e)
    email=$2
    shift 2
    ;;
  -m)
    master_ip=$2
    shift 2
    ;;
  --dry-run)
    dryrun=true
    shift
    ;;
  *) usage ;;
  esac
done

# validate required
: "${username:?Need -u USERNAME}"
: "${email:?Need -e EMAIL}"
: "${master_ip:?Need -m MASTER_IP}"

# email format
if ! [[ $email =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
  echo "Error: invalid email '$email'" >&2
  exit 1
fi

# derived names
cluster_name="${username}-cluster"
context_name="${username}@${cluster_name}"
kubeconfig_file="${username}.kubeconfig"
ns="${username}-profile"

# ---- check namespace ----
if ! kubectl get namespace "$ns" >/dev/null 2>&1; then
  echo "Namespace '$ns' does not exist."
  exit 1
fi

mkdir -p "$username"
cd "$username"

# fetch the CA cert from current kubeconfig
ca_data=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
echo "$ca_data" | base64 --decode >ca.crt

# ---- RBAC ----
rbac_manifest=$(mktemp)
trap 'rm -f ca.crt "$rbac_manifest" "$csr_manifest"' EXIT

cat >"$rbac_manifest" <<EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: $ns
  name: pod-admin
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get","list","watch","create","update","patch","delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: $ns
  name: pod-admin-binding
subjects:
- kind: User
  name: $email
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-admin
  apiGroup: rbac.authorization.k8s.io
EOF

# ---- CSR ----
openssl genrsa -out key.pem 2048
openssl req -new -key key.pem -out csr.pem -subj "/CN=$email/O=$username"

csr_b64=$(base64 <csr.pem | tr -d '\n')

csr_manifest=$(mktemp)
cat >"$csr_manifest" <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${username}-csr
spec:
  request: "$csr_b64"
  signerName: kubernetes.io/kube-apiserver-client
  usages: 
  - client auth
EOF

apply_cmd() {
  if $dryrun; then
    cat "$1"
    echo "----"
  else
    kubectl apply -f "$1"
  fi
}

# apply RBAC & CSR
apply_cmd "$rbac_manifest"
apply_cmd "$csr_manifest"

if ! $dryrun; then
  kubectl certificate approve ${username}-csr
  kubectl get csr ${username}-csr -o jsonpath='{.status.certificate}' |
    base64 --decode >crt.pem
fi

# ---- generate kubeconfig ----
if $dryrun; then
  echo "kubectl config set-cluster $cluster_name \\
    --server=https://$master_ip:6443 \\
    --certificate-authority=ca.crt \\
    --embed-certs=true \\
    --kubeconfig=$kubeconfig_file"
  echo "kubectl config set-credentials $email \\
    --client-certificate=crt.pem \\
    --client-key=key.pem \\
    --embed-certs=true \\
    --kubeconfig=$kubeconfig_file"
  echo "kubectl config set-context $context_name \\
    --cluster=$cluster_name \\
    --namespace=$ns \\
    --user=$email \\
    --kubeconfig=$kubeconfig_file"

  echo "usage: export KUBECONFIG=$PWD/$kubeconfig_file"
  echo "kubectl config use-context $context_name --kubeconfig=$kubeconfig_file"
else
  kubectl config set-cluster "$cluster_name" \
    --server="https://$master_ip:6443" \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --kubeconfig="$kubeconfig_file"

  kubectl config set-credentials "$email" \
    --client-certificate=crt.pem \
    --client-key=key.pem \
    --embed-certs=true \
    --kubeconfig="$kubeconfig_file"

  kubectl config set-context "$context_name" \
    --cluster="$cluster_name" \
    --namespace="$ns" \
    --user="$email" \
    --kubeconfig="$kubeconfig_file"

  export KUBECONFIG=$PWD/$kubeconfig_file
  kubectl config use-context $context_name

  echo "✅ Generated kubeconfig: $kubeconfig_file"
fi
