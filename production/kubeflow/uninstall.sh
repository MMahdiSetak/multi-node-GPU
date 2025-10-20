kustomize build ../kubeflow/manifests/example | kubectl delete --ignore-not-found --force --now -f -
kubectl delete namespace auth cert-manager istio-system knative-serving kubeflow kubeflow-user-example-com oauth2-proxy knative-eventing --force --grace-period=0
kubectl get namespace auth cert-manager istio-system knative-serving kubeflow kubeflow-user-example-com oauth2-proxy knative-eventing -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/<namespace>/finalize" -f -
kubectl get all,ingress,pvc,secrets,serviceaccounts,roles,clusterroles,clusterrolebindings,mutatingwebhookconfigurations,validatingwebhookconfigurations,crds -A | grep -E 'kubeflow|istio|knative|cert-manager'
kubectl get clusterroles |
    grep -E 'kubeflow|istio|knative|cert-manager' |
    awk '{print $1}' |
    xargs -I {} kubectl delete clusterrole {}
kubectl get clusterrolebindings |
    grep -E 'kubeflow|istio|knative|cert-manager' |
    awk '{print $1}' |
    xargs -I {} kubectl delete clusterrolebinding {}
kubectl get crd |
    grep -E 'kubeflow.org|istio.io|knative.dev|serving.kubeflow.org|cert-manager' |
    awk '{print $1}' |
    xargs kubectl delete crd --force --grace-period=0
kubectl delete mutatingwebhookconfigurations \
    $(kubectl get mutatingwebhookconfigurations | grep -E 'istio|kubeflow|cert-manager' | awk '{print $1}')
kubectl delete validatingwebhookconfigurations \
    $(kubectl get validatingwebhookconfigurations | grep -E 'istio|kubeflow|cert-manager' | awk '{print $1}')
kubectl delete clusterrolebinding meta-controller-cluster-role-binding