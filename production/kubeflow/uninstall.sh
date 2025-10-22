#!/bin/bash

# Retry loop for manifest deletion (handles transient termination delays)
while ! kustomize build ../kubeflow/manifests/example | kubectl delete --ignore-not-found --force --grace-period=0 -f -; do
  echo "Retrying manifest deletion..."
  sleep 10
done

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

# Delete namespaces (with finalizer patching for safety)
for ns in auth cert-manager istio-system knative-serving kubeflow kubeflow-user-example-com oauth2-proxy knative-eventing; do
  kubectl patch ns $ns -p '{"metadata":{"finalizers":null}}' --type=merge || true
  kubectl delete --ignore-not-found --force --grace-period=0 namespace $ns || true
done

# Delete profile-related user namespaces (with finalizer patching)
for ns in $(kubectl get namespace | grep -E '\-profile' | awk '{print $1}' 2>/dev/null); do
  kubectl patch ns $ns -p '{"metadata":{"finalizers":null}}' --type=merge || true
  kubectl delete ns $ns --ignore-not-found --force --grace-period=0 || true
done

# Delete ClusterRoles
kubectl get clusterroles |
    grep -E 'kubeflow|istio|knative|cert-manager' |
    awk '{print $1}' |
    xargs -I {} kubectl delete --ignore-not-found --force --grace-period=0 clusterrole {} || true

# Delete ClusterRoleBindings
kubectl get clusterrolebindings |
    grep -E 'kubeflow|istio|knative|cert-manager' |
    awk '{print $1}' |
    xargs -I {} kubectl delete --ignore-not-found --force --grace-period=0 clusterrolebinding {} || true

# Delete CRDs (with finalizer patching for common stuck ones)
for crd in $(kubectl get crd | grep -E 'kubeflow.org|istio.io|knative.dev|serving.kubeflow.org|cert-manager' | awk '{print $1}' 2>/dev/null); do
  kubectl patch crd $crd -p '{"metadata":{"finalizers":null}}' --type=merge || true
done
kubectl get crd |
    grep -E 'kubeflow.org|istio.io|knative.dev|serving.kubeflow.org|cert-manager' |
    awk '{print $1}' |
    xargs kubectl delete crd --ignore-not-found --force --grace-period=0 || true

# Delete MutatingWebhooks
kubectl delete --ignore-not-found --force --grace-period=0 mutatingwebhookconfigurations \
    $(kubectl get mutatingwebhookconfigurations | grep -E 'istio|kubeflow|cert-manager' | awk '{print $1}' 2>/dev/null) || true

# Delete ValidatingWebhooks
kubectl delete --ignore-not-found --force --grace-period=0 validatingwebhookconfigurations \
    $(kubectl get validatingwebhookconfigurations | grep -E 'istio|kubeflow|cert-manager' | awk '{print $1}' 2>/dev/null) || true

# Delete specific binding
kubectl delete --ignore-not-found --force --grace-period=0 clusterrolebinding meta-controller-cluster-role-binding || true

# Final verification (optional, but run manually after)
kubectl get all --all-namespaces | grep -E 'kubeflow|istio|knative|cert-manager' || echo "No remaining resources found."