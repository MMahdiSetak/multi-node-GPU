cd manifests

kubectl create namespace monitoring

# cat <<EOF | kubectl apply -f -
# apiVersion: v1
# kind: Secret
# metadata:
#   name: grafana-oauth-secret
#   namespace: monitoring
# type: Opaque
# stringData:
#   client_secret: LU5fS1isflKSCFYCcciuwhxsMxshNdky
# EOF

tee ./grafana-config.yaml <<- GRAFANA_CONFIG
apiVersion: v1
kind: Secret
metadata:
  labels:
    app.kubernetes.io/component: grafana
    app.kubernetes.io/name: grafana
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 12.0.0
  name: grafana-config
  namespace: monitoring
stringData:
  grafana.ini: |
    [auth]
    disable_login_form = false
    [auth.generic_oauth]
    allow_sign_up = true
    api_url = http://$KEYCLOAK_IP/auth/realms/infra/protocol/openid-connect/userinfo
    auth_url = http://$KEYCLOAK_IP/auth/realms/infra/protocol/openid-connect/auth
    auto_login = false
    client_id = grafana
    client_secret = yl0THzKH3PbWxmAFLiqrzJanZfA3Wa2F
    email_attribute_path = email
    enabled = true
    icon = signin
    login_attribute_path = username
    login_prompt = login
    name = Keycloak
    name_attribute_path = full_name
    role_attribute_path = contains(realm_access.roles[*], 'admin') && 'Admin' || 'Viewer'
    scopes = openid email profile
    signout_redirect_url = http://$KEYCLOAK_IP/auth/realms/infra/protocol/openid-connect/logout
    tls_skip_verify_insecure = true
    token_url = http://$KEYCLOAK_IP/auth/realms/infra/protocol/openid-connect/token
    use_refresh_token = true
    [date_formats]
    default_timezone = Asia/Tehran
    [security]
    allow_embedding = true
    [server]
    domain = $KUBEFLOW_IP
    root_url = http://$KUBEFLOW_IP/grafana/
    serve_from_sub_path = true
type: Opaque
GRAFANA_CONFIG


kubectl apply --server-side -f ../monitoring/manifests/setup
kubectl wait \
	--for condition=Established \
	--all CustomResourceDefinition \
	--namespace=monitoring
kubectl apply -f ../monitoring/manifests/


kubectl apply -f - <<'EOF'
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: nvidia-dcgm-exporter
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: nvidia-dcgm-exporter 
  namespaceSelector:
    matchNames:
    - gpu-operator
  endpoints:
  - port: gpu-metrics
    interval: 5s
    path: /metrics
EOF


kubectl delete NetworkPolicy grafana -n monitoring