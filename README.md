### Multi-Node GPU Cluster Deployment with Kubeflow on Kubernetes

This repository contains a series of scripts to deploy a multi-node GPU-enabled Kubernetes cluster for running Kubeflow workloads. The deployment can be carried out in two modes: experimental (using a Kind cluster) and production (using kubeadm). Below is a detailed guide for setting up the cluster.

---

### 1. **Prerequisites**
The following scripts configure the essential software components and drivers required for the cluster:

#### **containerd.sh**
Configures and enables the containerd runtime:
1. Installs `containerd.io`.
2. Generates a default configuration file and updates it to use `SystemdCgroup`.
3. Enables and restarts the containerd service.

#### **docker.sh**
Installs Docker as an alternative container runtime:
1. Installs Docker from the official script.
2. Configures Docker group for non-root usage.

#### **gpu-driver.sh**
Installs NVIDIA GPU drivers:
1. Updates system packages and configures NVIDIA CUDA repository.
2. Installs the required GPU drivers using the NVIDIA module.

#### **nvidia-container-toolkit.sh**
Configures NVIDIA container runtime for Docker and containerd:
1. Sets up NVIDIA Container Toolkit repository.
2. Installs the toolkit and configures it as the default runtime for both Docker and containerd.

#### **kind.sh**
Installs the Kind (Kubernetes in Docker) CLI:
1. Downloads and installs Kind for running Kubernetes clusters in Docker containers.

#### **helm.sh**
Installs Helm (Kubernetes package manager):
1. Downloads and installs Helm CLI.

#### **kubeadm.sh**
Sets up Kubernetes tools:
1. Configures the Kubernetes repository.
2. Installs `kubeadm`, `kubectl`, and `kubelet`.
3. Enables the kubelet service.

#### **mig.sh**
Configures NVIDIA Multi-Instance GPU (MIG) capabilities:
1. Enables and disables MIG mode.
2. Cleans up old GPU and compute instances.
3. Creates new MIG GPU instances.
4. Sets up a systemd service to configure MIG at system startup.

---

### 2. **Experimental Mode**
The experimental deployment uses **Kind** to set up a single-node cluster, suitable for testing and development.

#### **single-node-cluster.sh**
1. Installs all necessary prerequisites, including GPU drivers, Docker, NVIDIA container toolkit, and Kind.
2. Configures and deploys a Kind cluster named `kubeflow` with GPU support.
3. Sets up the Kubernetes environment inside the Kind control plane container:
   - Installs NVIDIA container toolkit.
   - Configures containerd to use NVIDIA runtime.
4. Deploys NVIDIA's Kubernetes device plugin for GPU support.
5. Deploys Kubeflow manifests using `kubectl kustomize`.
6. Exposes the cluster via port-forwarding for external access.

**Usage**:
```bash
bash single-node-cluster.sh
```
Navigate to `http://localhost:8080` to access the Kubeflow dashboard.

---

### 3. **Production Mode**
The production deployment is suitable for real-world use cases and leverages `kubeadm` for multi-node cluster configuration.

#### **all.sh**
Prepares the system for Kubernetes installation:
1. Disables swap and SELinux.
2. Configures sysctl parameters for Kubernetes networking.
3. Sets up hostnames and IP addresses in `/etc/hosts`.
4. Runs prerequisite scripts to install containerd and kubeadm.

#### **master.sh**
Sets up the master node:
1. Runs the `all.sh` script for system configuration.
2. Configures the firewall for Kubernetes control-plane ports.
3. Initializes the Kubernetes cluster with `kubeadm`.
4. Installs the Cilium CNI plugin.
5. Deploys NVIDIA's device plugin and Kubeflow manifests.
6. Exposes the cluster via port-forwarding.

**Usage**:
```bash
bash master.sh
```

#### **worker.sh**
Sets up worker nodes:
1. Runs the `all.sh` script for system configuration.
2. Configures the firewall for Kubernetes worker node ports.
3. Joins the worker node to the Kubernetes cluster using the token from the master node.

**Usage**:
```bash
bash worker.sh
```

---

### **Workflow Overview**
1. **Experimental**:
   - Run `single-node-cluster.sh` to quickly test Kubeflow on a Kind cluster.
2. **Production**:
   - Run `master.sh` on the master node.
   - Run `worker.sh` on each worker node.
   - Use the token from `kubeadm init` on the master to join workers.

This project ensures flexibility, allowing users to explore both experimental and production-grade cluster setups while leveraging GPU acceleration for AI/ML workloads with Kubeflow.
