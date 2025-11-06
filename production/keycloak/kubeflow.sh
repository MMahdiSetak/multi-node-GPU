KEYCLOAK_ISSUER="http://172.16.30.103/auth/realms/infra"
CLIENT_ID="kubeflow-oidc-authservice"
CLIENT_SECRET="ozUC0zcUqW3T9UA1LPnZVrmrPugXmfDK"
REDIRECT_URI="http://172.16.30.102/dex/callback"
DEX_ISSUER="http://172.16.30.102/dex"

kubectl rollout restart deployment dex -n auth

kustomize build common/dex/overlays/oauth2-proxy | kubectl delete -f -
kustomize build common/dex/overlays/oauth2-proxy | kubectl apply -f -
kustomize build common/oauth2-proxy/overlays/m2m-dex-only/ | kubectl delete -f -
kustomize build common/oauth2-proxy/overlays/m2m-dex-only/ | kubectl apply -f -
kustomize build common/istio-1-24/istio-install/overlays/oauth2-proxy | kubectl delete -f -
kustomize build common/istio-1-24/istio-install/overlays/oauth2-proxy | kubectl apply -f -
kustomize build common/oauth2-proxy/overlays/m2m-dex-only/ | kubectl delete -f -
kustomize build common/oauth2-proxy/overlays/m2m-dex-only/ | kubectl apply -f -