while ! kustomize build example | kubectl apply --server-side --force-conflicts -f -; do
    echo "Retrying to apply resources"
    sleep 20
done


kubectl -n kubeflow set env deployment jupyter-web-app-deployment APP_SECURE_COOKIES=false
kubectl -n kubeflow set env deployment volumes-web-app-deployment APP_SECURE_COOKIES=false

kubectl -n kubeflow rollout restart deployment jupyter-web-app-deployment
kubectl -n kubeflow rollout restart deployment volumes-web-app-deployment