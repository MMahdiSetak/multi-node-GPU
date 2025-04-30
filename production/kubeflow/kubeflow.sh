while ! kustomize build example | kubectl apply --server-side --force-conflicts -f -; do
    echo "Retrying to apply resources"
    sleep 20
done

kubectl port-forward --address 0.0.0.0 svc/istio-ingressgateway -n istio-system 8080:80
# Done!
# navigate to http://localhost:8080 user@example.com 12341234
kubectl -n istio-system port-forward --address 0.0.0.0 svc/istio-ingressgateway 443:443

kubectl -n istio-system patch svc istio-ingressgateway \
    --type='merge' \
    -p '{"spec": {"type": "NodePort"}}'

kubectl -n kubeflow set env deployment jupyter-web-app-deployment APP_SECURE_COOKIES=false
kubectl -n kubeflow set env deployment volumes-web-app-deployment APP_SECURE_COOKIES=false

kubectl -n kubeflow rollout restart deployment jupyter-web-app-deployment
kubectl -n kubeflow rollout restart deployment volumes-web-app-deployment
