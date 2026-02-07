helm uninstall keycloak -n keycloak
helm uninstall keycloak-db -n keycloak
kubectl delete namespace keycloak