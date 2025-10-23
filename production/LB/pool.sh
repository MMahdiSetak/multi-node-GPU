cat <<EOF | kubectl apply -f -
apiVersion: "cilium.io/v2"
kind: CiliumLoadBalancerIPPool
metadata:
  name: "blue-pool"
spec:
  blocks:
  - start: "172.16.30.100"
    stop: "172.16.30.200"
EOF


kubectl get ippools