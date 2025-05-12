curl -k -v -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "kerio_username=user-1696%40isiranco.internet&kerio_password=2wsx3edc%40WSX%23EDC" \
    https://192.168.10.2:4081/internal/dologin.php

curl -k -v -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "kerio_username=user-1696&kerio_password=4rfv5tgb%24RFV%25TGB" \
    https://192.168.10.2:4081/internal/dologin.php

kubeadm token create --print-join-command

kubectl get pods -A --field-selector spec.nodeName=worker-g01
kubectl delete pod -A --field-selector=status.phase=Succeeded
kubectl delete pod -A --field-selector=status.phase=Failed

# delete kubeflow
kustomize build example | kubectl delete --ignore-not-found --server-side --force-conflicts -f -
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

echo "Waiting for SSH on 192.168.20.139..."
until ssh -o BatchMode=yes \
    -o ConnectTimeout=5 \
    -o StrictHostKeyChecking=no \
    "setak@192.168.20.139" exit; do
    echo "  ⏳ SSH not ready yet – retrying in 5s…"
    sleep 5
done

systemctl set-default multi-user.target
systemctl set-default graphical.target

kubectl get pods --all-namespaces -o=jsonpath='{range .items[?(@.spec.volumes.persistentVolumeClaim.claimName=="storage-prometheus-alertmanager")]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}'

kubectl get pvc storage-prometheus-alertmanager-0 -o=jsonpath='{.spec.volumeName}'

kubectl describe pv pvc-bbefbc90-80a4-4138-911f-4c4a103cd61a
