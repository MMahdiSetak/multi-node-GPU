while ! kustomize build example | kubectl apply --server-side --force-conflicts -f -; do
    echo "Retrying to apply resources"
    sleep 20
done

kubectl port-forward --address 0.0.0.0 svc/istio-ingressgateway -n istio-system 8080:80
# Done!
# navigate to http://localhost:8080 user@example.com 12341234
