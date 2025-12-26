kubectl get nodes

kubectl cordon worker-s02

kubectl drain worker-s02 --ignore-daemonsets --delete-emptydir-data

kubectl delete node worker-s02