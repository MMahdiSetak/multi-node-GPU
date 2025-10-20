#!/usr/bin/env bash
set -euo pipefail
#dnf install httpd-tools
usage() {
    cat <<EOF >&2
Usage: $0 -u USERNAME -e EMAIL -p PASSWORD
  -u USERNAME   your username (required)
  -e EMAIL      your email address (required, must be valid format)
  -p PASSWORD   your password (required)
EOF
    exit 1
}

username=""
email=""
password=""

while getopts "u:e:p:" flag; do
    case "${flag}" in
    u) username=${OPTARG} ;;
    e) email=${OPTARG} ;;
    p) password=${OPTARG} ;;
    *) usage ;;
    esac
done

if [[ -z "$username" || -z "$email" || -z "$password" ]]; then
    echo "Error: -u, -e, -p are required." >&2
    usage
fi

if ! [[ $email =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    echo "Error: '$email' is not a valid email address." >&2
    exit 1
fi

cat <<EOF | kubectl apply -f -
apiVersion: kubeflow.org/v1
kind: Profile
metadata:
  name: $username-profile
spec:
  owner:
    kind: User
    name: $email
  resourceQuotaSpec:
    hard:
      limits.cpu: "8"
      limits.memory: 16Gi
      limits.nvidia.com/mig-2g.24gb: "1"
      limits.nvidia.com/mig-1g.12gb: "1"
EOF

hash=$(htpasswd -nbBC 10 "" "$password" | tr -d ':')

config=cm.yaml
if ! kubectl get configmap dex -n auth >/dev/null 2>&1; then
    echo "Error: ConfigMap 'dex' not found in 'auth' namespace." >&2
    exit 1
fi
kubectl get configmap dex -n auth -o yaml >"$config"
trap 'rm -f "$config"' EXIT

sed -i "/^    staticPasswords:/a\\
    - email: "$email"\\
      hash: \""$hash\""\\
      username: "$username"
" $config

kubectl apply -f "$config"

kubectl rollout restart deployment dex -n auth
