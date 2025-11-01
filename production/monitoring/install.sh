kubectl create namespace monitoring

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: grafana-oauth-secret
  namespace: monitoring
type: Opaque
stringData:
  client_secret: LU5fS1isflKSCFYCcciuwhxsMxshNdky
EOF


kubectl apply --server-side -f ../monitoring/manifests/setup
kubectl wait \
	--for condition=Established \
	--all CustomResourceDefinition \
	--namespace=monitoring
kubectl apply -f ../monitoring/manifests/


