cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: isillm-profile
  name: pod-admin
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
EOF

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-admin-binding
  namespace: isillm-profile
subjects:
- kind: User
  name: isillm@example.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-admin
  apiGroup: rbac.authorization.k8s.io
EOF

# Generate the private key
openssl genrsa -out isillm.key 2048

# Create a CSR; note that the CN must match the user name used in the RoleBinding.
openssl req -new -key isillm.key -out isillm.csr -subj "/CN=isillm@example.com/O=some-group"

cat isillm.csr | base64 | tr -d '\n'

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: isillm-csr
spec:
  request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJQ2R6Q0NBVjhDQVFBd01qRWJNQmtHQTFVRUF3d1NhWE5wYkd4dFFHVjRZVzF3YkdVdVkyOXRNUk13RVFZRApWUVFLREFwemIyMWxMV2R5YjNWd01JSUJJakFOQmdrcWhraUc5dzBCQVFFRkFBT0NBUThBTUlJQkNnS0NBUUVBCjdJQmRSWlNWT0Yza2l6eldhY0M0ODZNQW9rR21EMFR3K0pOc1VQZjJyTFpITVkwaURYYnliYjA5am9ieWlLb0wKVHFESFZvYXI5cXRsNThiMC9PREN6dlVWSDF5d25KUWltbHZkdFJ5QjRWRURKeDBWVlIvZ0tlSytpVUF5UldVbAp5NW5mc29wUXZyV1c1ckhiSFFWRzIycS9tQ1dEcmpDZy9Zc2pNbE9vZHFUQWxlRHdldHdvSjVTRUFxemlSSGs2ClNRaDNBNEllQXB5SXlRL3lWcy9GTjZIYTRMVEhNTGk5WjNsVmdDY0EyNmJ4MVp4cGg0ckZTWmZhejlJSWk0NGsKSHRnUHFzeU53U2ordnIvZzgxcWduZ0RYdG9URklFb2IrNURJNkVyN2RHL1MxUThOUGV4b1pGSHVRcENkaGdHbApnUDh4M0o1ZXBmRXJhcTNZM3NJMU13SURBUUFCb0FBd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFKSENhbGVXCit0RHpTaGFoNHd4bDVlODVqRUQ4R0x2TXR6Vjk4bFM0R1dqV1FlK3NJdFJOc1lKWGxlZ29qb0hBTVE0bXZVL28KYzZhM0prUHMyVGlBNzM0ZXVXWnlXQXVtaEFRNERoSThKUTNWTkppSzkvb0s2ejJ0c3FFbmRGSis1emVJMS9kQgpnbnZRenB2K0tJeTZMdXhISURVSFZ6Qyt6bVZxeDFLMkZqNmNCaHBPZ1E5cW9Hdzk2a0NZZWtYc0RHRDU1dUd0Ck01ZER1Q0VUeU4yTzFxbUt0alR6ZTQzdFlPclliMGNZNzNIdjJNamsxQVYxQmJ2OFVRWnFtZk5mOEZ2TlhzK3QKeDVWeVJkYS8vTHh0SCs3RTZ2QmpFbUhvb2hrN1VmSzZiQmRvNTFjbnlXNHB0WTJOSWJWNHpiL1pUZ0swcHN6SgplTmQwcGd5Rksya055S1E9Ci0tLS0tRU5EIENFUlRJRklDQVRFIFJFUVVFU1QtLS0tLQo=
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF

kubectl certificate approve isillm-csr

kubectl get csr isillm-csr -o jsonpath='{.status.certificate}' | base64 --decode >isillm.crt

kubectl config set-cluster my-cluster \
  --server=https://192.168.20.73:6443 \
  --certificate-authority=/etc/kubernetes/pki/ca.crt \
  --embed-certs=true \
  --kubeconfig=isillm.kubeconfig

# Set the user credentials using the signed certificate and key
kubectl config set-credentials isillm@example.com \
  --client-certificate=isillm.crt \
  --client-key=isillm.key \
  --embed-certs=true \
  --kubeconfig=isillm.kubeconfig

# Set the context to use the limited namespace (isillm-profile)
kubectl config set-context isillm-context \
  --cluster=my-cluster \
  --namespace=isillm-profile \
  --user=isillm@example.com \
  --kubeconfig=isillm.kubeconfig


kubectl config get-contexts
kubectl config use-context isillm-context
kubectl config current-context