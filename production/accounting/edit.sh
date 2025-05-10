kubectl describe quota kf-resource-quota -n admin-profile

kubectl edit Profile admin-profile

kubectl edit configmap dex -n auth

kubectl rollout restart deployment dex -n auth

kubectl get notebook -n admin-profile

kubectl edit notebook mig-test-cuda -n admin-profile
