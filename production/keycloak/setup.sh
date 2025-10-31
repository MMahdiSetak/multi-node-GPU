# https://github.com/codecentric/helm-charts/tree/master/charts/keycloakx

helm repo add codecentric https://codecentric.github.io/helm-charts
helm repo update
kubectl create namespace keycloak

cat << EOF | helm install keycloak-db bitnami/postgresql --namespace keycloak --create-namespace --values -
global:
  postgresql:
    auth:
      username: dbusername
      password: dbpassword
      database: keycloak
EOF


cat << EOF | helm install keycloak codecentric/keycloakx --namespace keycloak --create-namespace --values -
command:
  - "/opt/keycloak/bin/kc.sh"
  - "--verbose"
  - "start"
  - "--http-port=8080"
  - "--hostname-strict=false"
  - "--spi-events-listener-jboss-logging-success-level=info"
  - "--spi-events-listener-jboss-logging-error-level=warn"

extraEnv: |
  - name: KEYCLOAK_ADMIN
    valueFrom:
      secretKeyRef:
        name: {{ include "keycloak.fullname" . }}-admin-creds
        key: user
  - name: KEYCLOAK_ADMIN_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ include "keycloak.fullname" . }}-admin-creds
        key: password
  - name: JAVA_OPTS_APPEND
    value: >-
      -XX:MaxRAMPercentage=50.0
      -Djgroups.dns.query={{ include "keycloak.fullname" . }}-headless

service:
  type: LoadBalancer

dbchecker:
  enabled: true

database:
  vendor: postgres
  hostname: keycloak-db-postgresql
  port: 5432
  username: dbusername
  password: dbpassword
  database: keycloak

secrets:
  admin-creds:
    annotations:
      my-test-annotation: Test secret for {{ include "keycloak.fullname" . }}
    stringData:
      user: admin
      password: secret
EOF

helm uninstall keycloak -n keycloak
helm uninstall keycloak-db -n keycloak


# helm install keycloak codecentric/keycloakx \
#   --namespace keycloak \
#   --create-namespace \
#   --set keycloak.adminUser=admin \
#   --set keycloak.adminPassword=adminpassword \
#   --set keycloak.production=true \
#   --set postgresql.enabled=true \
#   --set postgresql.postgresqlPassword=pgpassword \
#   --set service.type=LoadBalancer \
#   --set service.httpPort=80 \
#   --set keycloak.extraEnv[0].name=KC_HOSTNAME_STRICT \
#   --set keycloak.extraEnv[0].value=false \
#   --set keycloak.extraEnv[1].name=KC_HOSTNAME_STRICT_HTTPS \
#   --set keycloak.extraEnv[1].value=false \
#   --set keycloak.extraEnv[2].name=KC_PROXY_HEADERS \
#   --set keycloak.extraEnv[2].value=xforwarded \
#   --set keycloak.extraEnv[3].name=KC_HTTP_ENABLED \
#   --set keycloak.extraEnv[3].value=true \
#   --set keycloak.extraArgs[0]=start \
#   --set keycloak.extraArgs[1]=--optimized \
#   --set image.repository=quay.io/keycloak/keycloak \
#   --set image.tag=latest

# cat <<EOF | helm install keycloak bitnami/keycloak --namespace keycloak -f -
# auth:
#   adminUser: admin
#   adminPassword: admin  # Change this
#   existingSecret: ""
# production: true
# postgresql:
#   enabled: true
#   auth:
#     postgresPassword: pg-admin  # Change this
#     username: keycloak
#     password: keycloak-db-123  # Change this
#     database: keycloak
#   primary:
#     persistence:
#       enabled: true
#       # storageClass: "your-storage-class"  # e.g., openebs-hostpath from your pods
#       size: 10Gi
# service:
#   type: LoadBalancer  # Uses Cilium L2 LB
# ingress:
#   enabled: false  # Use if you prefer Ingress over LB; set hostname and TLS
# EOF
