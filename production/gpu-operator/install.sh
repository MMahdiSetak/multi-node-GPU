kubectl create ns gpu-operator
kubectl label --overwrite ns gpu-operator pod-security.kubernetes.io/enforce=privileged

# helm repo add nvidia https://helm.ngc.nvidia.com/nvidia &&
#   helm repo update
# helm search repo nvidia

helm upgrade --install gpu-operator ./gpu-operator-v25.10.1.tgz -n gpu-operator --create-namespace --version=v25.10.1 --set driver.enabled=false --wait

# todo enable MIG based on configs

