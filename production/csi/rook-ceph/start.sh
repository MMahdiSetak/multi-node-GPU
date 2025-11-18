git clone --single-branch --branch v1.18.7 https://github.com/rook/rook.git

kubectl create -f crds.yaml -f common.yaml -f csi-operator.yaml -f operator.yaml
kubectl create -f cluster.yaml


kubectl create -f deploy/examples/toolbox.yaml
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- bash

ceph status
ceph osd status
ceph df
rados df

kubectl create -f deploy/examples/csi/rbd/storageclass.yaml

kubectl apply -f deploy/examples/filesystem.yaml
kubectl create -f deploy/examples/csi/cephfs/storageclass.yaml

kubectl apply -f deploy/examples/dashboard-loadbalancer.yaml
kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo