bash ../kubeflow/uninstall.sh
bash ../gpu-operator/uninstall.sh
bash ../monitoring/uninstall.sh
bash ../keycloak/uninstall.sh

cd kubespray
ansible all -i inventory/gpu-cluster/inventory.ini -b -m command -a "/usr/local/bin/nerdctl system prune -af"
cd ..

bash ../harbor/uninstall.sh