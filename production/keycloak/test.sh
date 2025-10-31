client_id: grafana
client_secret: LU5fS1isflKSCFYCcciuwhxsMxshNdky

auth_url: http://172.16.30.103/auth/realms/infra/protocol/openid-connect/auth

token_url: http://keycloak.keycloak.svc.cluster.local/auth/realms/infra/protocol/openid-connect/token
api_url: http://keycloak.keycloak.svc.cluster.local/auth/realms/infra/protocol/openid-connect/userinfo



wget --no-check-certificate \
  --method POST \
  --timeout=0 \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --body-data 'client_id=grafana&client_secret=LU5fS1isflKSCFYCcciuwhxsMxshNdky&grant_type=password&username=mahdi&password=test&scope=openid%20profile%20email' \
   'http://172.16.30.103/auth/realms/infra/protocol/openid-connect/token'