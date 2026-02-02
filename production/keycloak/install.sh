# kubectl create namespace keycloak
cat << EOF | helm upgrade --install keycloak-db ../pg/postgresql-18.2.0.tgz --namespace keycloak --create-namespace --values -
global:
  postgresql:
    auth:
      username: dbusername
      password: dbpassword
      database: keycloak
EOF

# TODO download the chart
cat << EOF | helm upgrade --install keycloak ./keycloakx-7.1.7.tgz --namespace keycloak --create-namespace --values -
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