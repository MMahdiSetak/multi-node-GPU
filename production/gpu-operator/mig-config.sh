nvidia-smi --query-gpu=index,name,pci.bus_id --format=csv

cat <<EOF | kubectl apply -n gpu-operator -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-mig-config
data:
  config.yaml: |
    version: v1
    mig-configs:
      all-disabled:
        - devices: all
          mig-enabled: false

      pcie-nvl:
        - devices: [0]
          mig-enabled: false
        - devices: [1]
          mig-enabled: false
        - devices: [2]
          mig-enabled: false
        - devices: [3]
          mig-enabled: false
        - devices: [4]
          mig-enabled: true
          mig-devices:
            "3g.40gb": 1
            "2g.20gb": 1
            "1g.10gb": 1
EOF


cat <<EOF | kubectl apply -n gpu-operator -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-mig-config
data:
  config.yaml: |
    version: v1
    mig-configs:
      all-disabled:
        - devices: all
          mig-enabled: false

      pcie-nvl:
        - devices: [4]
          mig-enabled: true
          mig-devices:
            "4g.40gb": 1
            "2g.20gb": 1
            "1g.10gb": 1
EOF

cat <<EOF | kubectl apply -n gpu-operator -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-mig-config
data:
  config.yaml: |
    version: v1
    mig-configs:
      all-disabled:
        - devices: all
          mig-enabled: false

      test:
        - devices: all
          mig-enabled: true
          mig-devices:
            "2g.20gb": 3
            "1g.10gb": 1
EOF

kubectl patch clusterpolicies.nvidia.com/cluster-policy \
    --type='json' \
    -p='[{"op":"replace", "path":"/spec/mig/strategy", "value":"mixed"}]'

kubectl patch clusterpolicies.nvidia.com/cluster-policy \
    --type='json' \
    -p='[{"op":"replace", "path":"/spec/migManager/config/name", "value":"custom-mig-config"}]'

kubectl label nodes master nvidia.com/mig.config=all-enable --overwrite

kubectl logs -n gpu-operator -l app=nvidia-mig-manager -c nvidia-mig-manager

kubectl label nodes worker-g01 nvidia.com/mig.config=pcie --overwrite
# pcie-nvl
kubectl label nodes worker-g01 nvidia.com/mig.config=all-disabled --overwrite

cat <<EOF | kubectl apply -n gpu-operator -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-mig-config
data:
  config.yaml: |
    version: v1
    mig-configs:
      all-disabled:
        - devices: all
          mig-enabled: false

      pcie:
        - devices: [0]
          mig-enabled: false
        - devices: [1]
          mig-enabled: true
          mig-devices:
            "1g.10gb": 7
EOF