#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<EOF >&2
Usage: $0 -u USERNAME
  -u USERNAME   your username (required)
EOF
    exit 1
}

username=""

while getopts "u:" flag; do
    case "${flag}" in
    u) username=${OPTARG} ;;
    *) usage ;;
    esac
done

if [[ -z "$username" ]]; then
    echo "Error: -u is required." >&2
    usage
fi

kubectl delete profile "$username"-profile

config=cm.yaml
if ! kubectl get configmap dex -n auth >/dev/null 2>&1; then
    echo "Error: ConfigMap 'dex' not found in 'auth' namespace." >&2
    exit 1
fi
kubectl get configmap dex -n auth -o yaml >"$config"
trap 'rm -f "$config"' EXIT

#yq eval "del(.data.\"config.yaml\" | fromyaml | .staticPasswords[] | select(.username == \"$username\")) | .data.\"config.yaml\" = (.|fromyaml|toyaml)" -i dex-cm.yaml
sed -i -E "/^    - email:/{
    N;N
    /username: $username$/d
}" "$config"

kubectl apply -f "$config"

kubectl rollout restart deployment dex -n auth

if grep -q "username: $username" "$config"; then
    echo "Warning: user '$username' still present in ConfigMap" >&2
    exit 1
fi
