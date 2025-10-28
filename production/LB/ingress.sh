cat << EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: grafana-gateway
  namespace: monitoring
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "grafana.172.16.30.101.nip.io"
EOF


cat << EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: grafana-vs
  namespace: monitoring
spec:
  hosts:
  - "grafana.172.16.30.101.nip.io"
  gateways:
  - grafana-gateway
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: grafana.monitoring.svc.cluster.local
        port:
          number: 3000
EOF

cat << EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: grafana-dr
  namespace: monitoring
spec:
  host: grafana.monitoring.svc.cluster.local
  trafficPolicy:
    tls:
      mode: DISABLE
EOF


kubectl label namespace monitoring istio-injection=enabled --overwrite


kubectl get authorizationpolicies --all-namespaces
cat <<EOF | kubectl apply -f -
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-grafana
  namespace: istio-system  # Apply here to target the gateway
spec:
  selector:
    matchLabels:
      istio: ingressgateway  # Targets ingress gateway pods
  action: ALLOW
  rules:
  - when:
    - key: request.headers[host]
      values: ["grafana.172.16.30.101.nip.io"]  # Matches your host
EOF


kubectl get authorizationpolicy --all-namespaces

kubectl edit authorizationpolicy istio-ingressgateway-oauth2-proxy -n istio-system

apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  creationTimestamp: "2025-10-22T15:52:04Z"
  generation: 1
  name: istio-ingressgateway-oauth2-proxy
  namespace: istio-system
  resourceVersion: "10153197"
  uid: 05a98819-3da5-4a05-b371-8e4afae73d71
spec:
  action: CUSTOM
  provider:
    name: oauth2-proxy
  rules:
  - to:
    - operation:
        notPaths:
        - /dex/*
        - /dex/**
        - /oauth2/*
    when:
    - key: request.headers[authorization]
      notValues:
      - '*'
    - key: request.headers[host]
      notValues:
      - "grafana.172.16.30.101.nip.io"
  selector:
    matchLabels:
      app: istio-ingressgateway

kubectl edit authorizationpolicy istio-ingressgateway-require-jwt -n istio-system

    when:
    - key: request.headers[host]
      notValues:
      - "grafana.172.16.30.101.nip.io"

kubectl rollout restart deployment istio-ingressgateway -n istio-system


cat <<EOF | kubectl apply -f -
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-grafana-inbound
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app.kubernetes.io/component: grafana  # Matches your Grafana pod labels
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["istio-system"]  # From ingress gateway namespace
        principals: ["cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]  # Gateway SA; adjust if your SA name differs
    to:
    - operation:
        ports: ["3000"]  # Grafana port
EOF

kubectl rollout restart deployment grafana -n monitoring
kubectl rollout restart deployment istio-ingressgateway -n istio-system



apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  creationTimestamp: "2025-10-22T15:52:04Z"
  generation: 1
  name: global-deny-all
  namespace: istio-system
  resourceVersion: "10153195"
  uid: ef1274ae-f773-4f08-a135-2e425d720541
spec: {}
kubectl delete authorizationpolicy global-deny-all -n istio-system