cat <<EOF | kubectl apply -f -
apiVersion: "cilium.io/v2"
kind: CiliumLoadBalancerIPPool
metadata:
  name: "blue-pool"
spec:
  blocks:
  - start: "172.16.30.101"
    stop: "172.16.30.200"
EOF


kubectl get ippools


cat <<EOF | kubectl apply -f -
apiVersion: "cilium.io/v2alpha1"
kind: CiliumL2AnnouncementPolicy
metadata:
  name: local-announce-policy
spec:
#   serviceSelector:
#     matchLabels:
#       color: blue
  nodeSelector:
    matchExpressions:
      - key: node-role.kubernetes.io/control-plane
        operator: DoesNotExist
  interfaces:
  - ^ens[0-9]+
  externalIPs: true
  loadBalancerIPs: true
EOF

kubectl edit svc istio-ingressgateway -n istio-system
kubectl edit svc -n monitoring prometheus-k8s
type: LoadBalancer
externalTrafficPolicy: Cluster


kubectl edit clusterrole cilium
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  verbs:
  - create
  - get
  - update
  - list
  - delete

kubectl -n kube-system rollout restart ds cilium

# Troubleshooting
kubectl -n kube-system exec ds/cilium -- cilium-dbg config --all | grep EnableL2Announcements
kubectl -n kube-system exec ds/cilium -- cilium-dbg config --all | grep KubeProxyReplacement
kubectl -n kube-system exec ds/cilium -- cilium-dbg config --all | grep EnableExternalIPs

kubectl get CiliumL2AnnouncementPolicy
kubectl get leases -n kube-system

kubectl -n kube-system get lease | grep "cilium-l2announce"

kubectl -n kube-system logs ds/cilium | grep "l2"
kubectl -n kube-system logs ds/cilium | grep "error"
kubectl logs -n kube-system -l app.kubernetes.io/name=cilium-agent | grep -E 'l2|lease|error|forbidden'
kubectl logs -n kube-system -l app.kubernetes.io/name=cilium-operator | grep -E 'l2|lease|error|forbidden'

kubectl get svc istio-ingressgateway -n istio-system


kubectl run tmp-shell --image=busybox --rm -it -- /bin/sh
# Inside the pod:
wget --spider http://grafana.monitoring.svc.cluster.local:3000
exit


#solved:
kubectl delete NetworkPolicy grafana -n monitoring

#maybe update?
spec:
  ingress:
  - from:
    - podSelector: {}  # Allows from all pods in the same namespace
    - namespaceSelector: {}  # Allows from all other namespaces
    - ipBlock:
        cidr: 0.0.0.0/0  # Allows external traffic (e.g., via LoadBalancer); replace with your local CIDR like 172.16.0.0/16 for safety
    ports:
    - port: 3000
      protocol: TCP
  - from:  # Keep the existing rule for Prometheus
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: prometheus
    ports:
    - port: 3000
      protocol: TCP