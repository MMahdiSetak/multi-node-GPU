helm upgrade --install kubecost ./kubecost-3.1.3.tgz --namespace kubecost --create-namespace --wait \
  --set frontend.service.type=LoadBalancer \
  --set frontend.service.annotations={"lbipam.cilium.io/ips": "'${KUBECOST_IP}'"}} \
  # --set finopsagent.enabled=false \
  # --set ?=http://prometheus-k8s.monitoring.svc.cluster.local:9090