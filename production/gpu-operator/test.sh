kubectl uncordon worker-g01

cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: cuda-vectoradd
spec:
  restartPolicy: OnFailure
  containers:
  - name: vectoradd
    image: nvcr.io/nvidia/k8s/cuda-sample:vectoradd-cuda12.5.0
    resources:
      limits:
        nvidia.com/mig-3g.47gb: 1
EOF

# cat <<EOF | kubectl create -f -
# apiVersion: v1
# kind: Pod
# metadata:
#   name: cuda-vectoradd
# spec:
#   restartPolicy: OnFailure
#   containers:
#   - name: vectoradd
#     image: nvcr.io/nvidia/k8s/cuda-sample:vectoradd-cuda12.5.0
#     resources:
#       limits:
#         nvidia.com/gpu: 1
#   nodeSelector:
#     nvidia.com/mig-3g.47gb.product: NVIDIA-H100-NVL-MIG-3g.47gb
# EOF
