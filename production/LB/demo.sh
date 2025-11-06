cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-demo
  template:
    metadata:
      labels:
        app: nginx-demo
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        command: ["/bin/sh"]
        args:
        - "-c"
        - "POD_INDEX=$(hostname | cut -d- -f3); echo \"welcome $((POD_INDEX + 1))\" > /usr/share/nginx/html/index.html && exec nginx -g 'daemon off;'"
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: nginx-demo
EOF


nano /usr/share/nginx/html/index.html

kubectl exec -it nginx-demo-2 -- sh
apt update
apt install nano
nano /usr/share/nginx/html/index.html