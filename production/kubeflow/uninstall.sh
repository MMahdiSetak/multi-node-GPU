kustomize build ../kubeflow/manifests/example | kubectl delete --ignore-not-found --force -f -

# Scale down Profiles controller to prevent reconciliation
kubectl -n kubeflow scale deployment profiles-deployment --replicas=0 || true

# Patch finalizers on all Profiles (removes blocks)
for profile in $(kubectl get profiles.kubeflow.org --all-namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null); do
  ns=$(kubectl get profiles.kubeflow.org $profile --all-namespaces -o jsonpath='{.metadata.namespace}' 2>/dev/null)
  if [ -n "$ns" ]; then
    kubectl patch profiles.kubeflow.org $profile -n $ns -p '{"metadata":{"finalizers":null}}' --type=merge || true
  else
    kubectl patch profiles.kubeflow.org $profile -p '{"metadata":{"finalizers":null}}' --type=merge || true
  fi
done

# Now delete Profiles (should succeed without stuck state)
kubectl delete profiles.kubeflow.org --all --all-namespaces --force --grace-period=0 || true

# Patch finalizers on Profiles CRD (if stuck)
kubectl patch crd profiles.kubeflow.org -p '{"metadata":{"finalizers":null}}' --type=merge || true

kubectl delete --ignore-not-found --force --grace-period=0 namespace auth cert-manager istio-system knative-serving kubeflow kubeflow-user-example-com oauth2-proxy knative-eventing

kubectl get clusterroles |
    grep -E 'kubeflow|istio|knative|cert-manager' |
    awk '{print $1}' |
    xargs -I {} kubectl delete --ignore-not-found --force clusterrole {}

kubectl get clusterrolebindings |
    grep -E 'kubeflow|istio|knative|cert-manager' |
    awk '{print $1}' |
    xargs -I {} kubectl delete --ignore-not-found --force clusterrolebinding {}

kubectl delete profiles.kubeflow.org --all --all-namespaces --force --grace-period=0

kubectl get namespace |
    grep -E '\-profile' |
    awk '{print $1}' |
    xargs kubectl delete ns --ignore-not-found --force --grace-period=0

kubectl get crd |
    grep -E 'kubeflow.org|istio.io|knative.dev|serving.kubeflow.org|cert-manager' |
    awk '{print $1}' |
    xargs kubectl delete crd --ignore-not-found --force --grace-period=0

kubectl delete --ignore-not-found --force mutatingwebhookconfigurations \
    $(kubectl get mutatingwebhookconfigurations | grep -E 'istio|kubeflow|cert-manager' | awk '{print $1}')

kubectl delete --ignore-not-found --force validatingwebhookconfigurations \
    $(kubectl get validatingwebhookconfigurations | grep -E 'istio|kubeflow|cert-manager' | awk '{print $1}')

kubectl delete --ignore-not-found --force clusterrolebinding meta-controller-cluster-role-binding