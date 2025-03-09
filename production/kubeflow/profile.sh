cat <<EOF | kubectl apply -f -
apiVersion: kubeflow.org/v1
kind: Profile
metadata:
  name: admin01-profile
spec:
  owner:
    kind: User
    name: admin01@example.com
  resourceQuotaSpec:
    hard:
      limits.cpu: "8"
      limits.memory: 16Gi
      limits.nvidia.com/mig-2g.24gb: "1"
      limits.nvidia.com/mig-1g.12gb: "1"
EOF

kubectl edit Profile admin01-profile -n admin01-profile
kubectl describe quota kf-resource-quota -n admin01-profile
kubectl edit configmap dex -n auth
kubectl rollout restart deployment dex -n auth


kubectl get notebook -n admin01-profile
kubectl edit notebook mig-test -n admin01-profile
kubectl edit notebook mig-2g-24gb-test -n admin01-profile

nvidia.com/mig-1g.12gb: "1"
nvidia.com/mig-2g.24gb: "1"



#############
kubectl apply -f my-profile.yaml


apiVersion: kubeflow.org/v1beta1
kind: Profile
metadata:
  name: test-user-profile   #replace with the name of profile you want, this will be user's namespace name
spec:
  owner:
    kind: User
    name: test-user@kubeflow.org
  resourceQuotaSpec:    # resource quota can be set optionally
    hard:
      limits.cpu: "8"
      limits.memory: 16Gi
      requests.nvidia.com/gpu: "1"
      persistentvolumeclaims: "1"
      requests.storage: "5Gi"


nvidia.com/gpu
nvidia.com/mig-1g.10gb
nvidia.com/mig-1g.12gb
nvidia.com/mig-2g.20gb
nvidia.com/mig-2g.24gb
nvidia.com/mig-3g.40gb
nvidia.com/mig-3g.47gb



cat <<EOF | kubectl apply -f -
apiVersion: kubeflow.org/v1
kind: Profile
metadata:
  name: malek01-profile
spec:
  owner:
    kind: User
    name: malek01@example.com
  resourceQuotaSpec:
    hard:
      limits.cpu: "16"
      limits.memory: 20Gi
      limits.nvidia.com/mig-2g.20gb: "1"
EOF
kubectl edit Profile malek01-profile -n malek01-profile
kubectl describe quota kf-resource-quota -n malek01-profile
kubectl get notebook -n malek01-profile
kubectl edit notebook mig-2g-20gb -n malek01-profile


cat <<EOF | kubectl apply -f -
apiVersion: kubeflow.org/v1
kind: Profile
metadata:
  name: malek02-profile
spec:
  owner:
    kind: User
    name: malek02@example.com
  resourceQuotaSpec:
    hard:
      limits.cpu: "32"
      limits.memory: 32Gi
      limits.nvidia.com/mig-3g.40gb: "1"
EOF
kubectl edit Profile malek02-profile -n malek02-profile
kubectl describe quota kf-resource-quota -n malek02-profile
kubectl get notebook -n malek02-profile
kubectl edit notebook mig-3g-40gb -n malek02-profile


kubectl delete profile user01-profile
kubectl delete namespace user01-profile
