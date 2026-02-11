cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: grafana
  namespace: kubeflow  # Or the namespace where your Istio ingress gateway is
spec:
  hosts:
  - "*"  # Or your specific Kubeflow domain if using external DNS
  gateways:
  - kubeflow-gateway
  http:
  - match:
    - uri:
        prefix: /grafana/
    rewrite:
      uri: /
    route:
    - destination:
        host: grafana.monitoring.svc.cluster.local  
        port:
          number: 80
EOF

cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: grafana
  namespace: kubeflow  # Or the namespace where your Istio ingress gateway is
spec:
  hosts:
  - "*"  # Or your specific Kubeflow domain if using external DNS
  gateways:
  - kubeflow-gateway
  http:
  - match:
    - uri:
        prefix: /grafana/
    route:
    - destination:
        host: grafana.monitoring.svc.cluster.local  
        port:
          number: 80
EOF

kubectl edit configmap centraldashboard-config -n kubeflow


"externalLinks": [
            {
                "type": "item",
                "iframe": true,
                "text": "Monitoring",
                "link": "/grafana/d/pgv-h42QjU_J",
                "icon": "launch"
            }
        ],
