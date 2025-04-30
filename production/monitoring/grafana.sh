helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install grafana grafana/grafana

kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode
echo
9YBCLevyKlV4gddV42VjQlTF8xT4j5bTymwf1Dgi

kubectl port-forward service/grafana 3000:80
#https://github.com/dotdc/grafana-dashboards-kubernetes
#https://grafana.com/grafana/dashboards/18288-nvidia-gpu/
#12239
# NOTES:
# 1. Get your 'admin' user password by running:

#    kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# 2. The Grafana server can be accessed via port 80 on the following DNS name from within your cluster:

#    grafana.default.svc.cluster.local

#    Get the Grafana URL to visit by running these commands in the same shell:
#      export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")
#      kubectl --namespace default port-forward $POD_NAME 3000

# 3. Login with the password from step 1 and the username: admin
# #################################################################################
# ######   WARNING: Persistence is disabled!!! You will lose your data when   #####
# ######            the Grafana pod is terminated.                            #####
# #################################################################################
