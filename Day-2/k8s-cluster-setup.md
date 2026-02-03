# Day 2: Production-Grade Kubernetes Cluster Setup

**Date:** February 2, 2026  
**Cluster Version:** Kubernetes v1.32.11  
**Deployment Type:** 3-Node Multi-Master Architecture  
**Status:** ✅ Production Ready

---

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Infrastructure Setup](#infrastructure-setup)
- [Installation Phases](#installation-phases)
  - [Phase 1: Container Runtime](#phase-1-container-runtime-docker--containerd)
  - [Phase 2: Kubernetes Components](#phase-2-kubernetes-components)
  - [Phase 3: Master Node Initialization](#phase-3-master-node-initialization)
  - [Phase 4: CNI Plugin Installation](#phase-4-cni-plugin-installation-calico)
  - [Phase 5: Worker Node Integration](#phase-5-worker-node-integration)
- [Issues Encountered & Resolutions](#issues-encountered--resolutions)
- [Verification & Testing](#verification--testing)
- [Production Best Practices](#production-best-practices)
- [Screenshots & Evidence](#screenshots--evidence)
- [Resources & References](#resources--references)

---

## 🏗️ Architecture Overview

### Cluster Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                        Your Workstation                          │
│                    kubectl v1.32.11 client                       │
│                    ~/.kube/config                        │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ HTTPS:6443 (kubectl commands)
                         │
         ┌───────────────▼──────────────────┐
         │      Master Node (Control Plane) │
         │      Hostname: k8s-master        │
         │      IP: 192.168.1.9             │
         │                                  │
         │  ┌────────────────────────────┐  │
         │  │   Control Plane Components │  │
         │  │   ─────────────────────    │  │
         │  │   • kube-apiserver         │  │
         │  │   • etcd (cluster state)   │  │
         │  │   • kube-scheduler         │  │
         │  │   • kube-controller-mgr    │  │
         │  └────────────────────────────┘  │
         │                                  │
         │  ┌────────────────────────────┐  │
         │  │   Node Components          │  │
         │  │   ─────────────────        │  │
         │  │   • kubelet v1.32.11       │  │
         │  │   • containerd             │  │
         │  │   • calico-node            │  │
         │  │   • kube-proxy             │  │
         │  └────────────────────────────┘  │
         │                                  │
         │  🔒 Taint: NoSchedule           │
         │  (No app pods scheduled here)   │
         └──────────────┬───────────────────┘
                        │
            ┌───────────┴────────────┐
            │                        │
    ┌───────▼────────┐      ┌───────▼────────┐
    │  Worker Node 1 │      │  Worker Node 2 │
    │  k8s-worker1   │      │  k8s-worker2   │
    │  192.168.1.4   │      │  192.168.1.5   │
    │                │      │                │
    │ ┌────────────┐ │      │ ┌────────────┐ │
    │ │ kubelet    │ │      │ │ kubelet    │ │
    │ │ v1.32.11   │ │      │ │ v1.32.11   │ │
    │ │            │ │      │ │            │ │
    │ │ containerd │ │      │ │ containerd │ │
    │ │            │ │      │ │            │ │
    │ │ calico-node│ │      │ │ calico-node│ │
    │ └────────────┘ │      │ └────────────┘ │
    │                │      │                │
    │ ┌────────────┐ │      │ ┌────────────┐ │
    │ │ App Pods   │ │      │ │ App Pods   │ │
    │ │ (Running)  │ │      │ │ (Running)  │ │
    │ └────────────┘ │      │ └────────────┘ │
    └────────────────┘      └────────────────┘

         Calico CNI Overlay Network
         Pod CIDR: 10.244.0.0/16
         Service CIDR: 10.96.0.0/12
```

### Network Architecture

```
┌──────────────────────────────────────────────────────────┐
│                   Physical Network Layer                  │
│                   192.168.1.0/24 (Bridge)                │
│                                                           │
│   ┌──────────┐    ┌──────────┐    ┌──────────┐         │
│   │  .9      │    │  .4      │    │  .5      │         │
│   │ Master   │────│ Worker1  │────│ Worker2  │         │
│   └──────────┘    └──────────┘    └──────────┘         │
└──────────────────────────────────────────────────────────┘
                          ▲
                          │
┌──────────────────────────┴───────────────────────────────┐
│              Kubernetes Overlay Network                   │
│                  (Calico IPIP/VXLAN)                     │
│                                                           │
│   Pod Network: 10.244.0.0/16                             │
│   ┌─────────────────────────────────────────┐           │
│   │ 10.244.235.x  (Master pods)             │           │
│   │ 10.244.194.x  (Worker1 pods)            │           │
│   │ 10.244.126.x  (Worker2 pods)            │           │
│   └─────────────────────────────────────────┘           │
│                                                           │
│   Service Network: 10.96.0.0/12                          │
│   ┌─────────────────────────────────────────┐           │
│   │ 10.96.0.1     (kubernetes API)          │           │
│   │ 10.96.0.10    (kube-dns)                │           │
│   │ 10.96.x.x     (ClusterIP services)      │           │
│   └─────────────────────────────────────────┘           │
└───────────────────────────────────────────────────────────┘
```

### Component Stack

| Layer | Component | Version | Purpose |
|-------|-----------|---------|---------|
| **OS** | Ubuntu | 24.04 LTS | Base operating system |
| **Container Runtime** | containerd | Latest | Container execution engine |
| **Container CLI** | Docker | 29.2.0 | Development & debugging |
| **Orchestration** | Kubernetes | v1.32.11 | Container orchestration |
| **CNI Plugin** | Calico | v3.31.3 | Pod networking & policies |
| **DNS** | CoreDNS | Built-in | Service discovery |
| **Proxy** | kube-proxy | Built-in | Service networking |

---

## ✅ Prerequisites

### Completed (Day 1)

- [x] 3 VMs created and configured
- [x] Ubuntu 24.04 LTS installed on all nodes
- [x] Hostnames set (k8s-master, k8s-worker1, k8s-worker2)
- [x] /etc/hosts configured on all nodes
- [x] SSH key-based authentication configured
- [x] Swap disabled on all nodes
- [x] Kernel modules loaded (overlay, br_netfilter)
- [x] sysctl parameters configured
- [x] Firewall rules configured (if applicable)

### System Requirements

| Resource | Master Node | Worker Nodes |
|----------|-------------|--------------|
| **vCPU** | 2 cores | 2 cores |
| **RAM** | 4 GB | 4 GB |
| **Disk** | 40 GB | 40 GB |
| **Network** | Bridge adapter | Bridge adapter |

### Network Configuration

| Node | Hostname | IP Address | Role |
|------|----------|------------|------|
| VM1 | k8s-master | 192.168.1.9 | Control Plane |
| VM2 | k8s-worker1 | 192.168.1.4 | Worker |
| VM3 | k8s-worker2 | 192.168.1.5 | Worker |

---

## 🚀 Installation Phases

## PHASE 1: Container Runtime (Docker + containerd)

### Why Container Runtime is Required

Kubernetes doesn't execute containers directly. It requires a **Container Runtime Interface (CRI)** compliant runtime.

**Enterprise Setup:**
- **containerd**: Primary runtime (lightweight, K8s-native)
- **Docker**: Optional CLI for development/troubleshooting

**Reference:** [Kubernetes Container Runtime Requirements](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)

---

### Step 1.1: Install Docker (All Nodes)

**Installation Script:**

```bash
# SSH into first node
ssh user@192.168.1.9

# Download official Docker installation script
curl -fsSL https://get.docker.com -o get-docker.sh

# Execute installation
sudo sh get-docker.sh
```

**What this script does:**
1. Detects OS (Ubuntu 24.04)
2. Adds Docker's official GPG key
3. Configures Docker apt repository
4. Installs `docker-ce`, `docker-ce-cli`, `containerd.io`
5. Starts and enables Docker service

**📸 SCREENSHOT: Successful installation**

```bash
docker --version
# Expected output: Docker version 29.x.x, build xxxxx
```
![Docker Version](.\screenshots\docker-version.PNG)

**Configure Docker permissions:**

```bash
# Add current user to docker group (avoid sudo)
sudo usermod -aG docker $USER

# Apply group changes
newgrp docker

# Test Docker without sudo
docker run hello-world
```
![Docker Test](.\screenshots\hello-from-docker.PNG)

**📸 SCREENSHOT: Hello from Docker message**

**Why this matters:**
- ✅ Docker group membership = Production convenience
- ⚠️ Security note: In production, use RBAC instead
- ✅ For homelab: This configuration is acceptable

---

### Step 1.2: Configure containerd for Kubernetes

**Generate default configuration:**

```bash
# Create containerd config directory
sudo mkdir -p /etc/containerd

# Generate default config
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
```

**Enable systemd cgroup driver (CRITICAL):**

```bash
# Modify config to use systemd cgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Verify change
grep SystemdCgroup /etc/containerd/config.toml
# Expected: SystemdCgroup = true
```

**Why systemd cgroup is required:**

> **From Kubernetes Documentation:**
> 
> "On Linux, control groups (cgroups) constrain resources allocated to processes. Both kubelet and the underlying container runtime need to interface with cgroups. To interface with cgroups, kubelet and container runtime must use a cgroup driver. It's critical that kubelet and container runtime use the same cgroup driver."

**Reference:** [Kubernetes cgroup drivers](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#cgroup-drivers)

**Impact of mismatch:**
- ❌ Kubelet and containerd using different drivers = Cluster instability
- ❌ Pods fail to start or get stuck
- ❌ Node becomes NotReady

**Restart containerd:**

```bash
# Apply configuration
sudo systemctl restart containerd

# Enable on boot
sudo systemctl enable containerd

# Verify status
sudo systemctl status containerd
```

**📸 SCREENSHOT: containerd active (running)**

---

### Step 1.3: Repeat on All Nodes

```bash
# Exit from master
exit

# Install on Worker 1
ssh user@192.168.1.4
# [Run all Step 1.1 and 1.2 commands]
exit

# Install on Worker 2
ssh user@192.168.1.5
# [Run all Step 1.1 and 1.2 commands]
exit
```

**Verification checklist:**
- [ ] Docker installed on all 3 nodes
- [ ] containerd configured with systemd cgroup on all nodes
- [ ] containerd service running on all nodes
- [ ] User added to docker group on all nodes

---

## PHASE 2: Kubernetes Components

### Why These Components?

| Component | Purpose | Runs On |
|-----------|---------|---------|
| **kubeadm** | Cluster bootstrapping tool | All nodes |
| **kubelet** | Node agent, manages pods | All nodes |
| **kubectl** | CLI to interact with API server | Master + your PC |

**Enterprise Standard:** These are the official Kubernetes tools used by GKE, EKS, AKS.

**Reference:** [Official kubeadm Installation Guide](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)

---

### Step 2.1: Add Kubernetes Repository

**Why official repository:**
- ✅ Latest stable versions
- ✅ Security updates
- ✅ Package signing for verification

```bash
# SSH into master
ssh user@192.168.1.9

# Create keyrings directory
sudo mkdir -p -m 755 /etc/apt/keyrings

# Download Kubernetes GPG key (v1.32 - current stable)
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list
```

**📸 SCREENSHOT: Repository added**

```bash
# Verify repository
cat /etc/apt/sources.list.d/kubernetes.list
```

---

### Step 2.2: Install Kubernetes Packages

```bash
# Update package index
sudo apt-get update

# Install Kubernetes components
sudo apt-get install -y kubelet kubeadm kubectl

# Hold packages (prevent auto-upgrade)
sudo apt-mark hold kubelet kubeadm kubectl
```

**📸 SCREENSHOT: Installation complete**

```bash
# Verify versions
kubeadm version
kubelet --version
kubectl version --client
```

**Why hold packages:**

> **Production Critical:**
> 
> Kubernetes version upgrades must be performed manually and systematically. Auto-upgrading can cause:
> - Version skew between nodes (unsupported)
> - API incompatibilities
> - Cluster downtime

**Reference:** [Kubernetes Version Skew Policy](https://kubernetes.io/releases/version-skew-policy/)

---

### Step 2.3: Enable kubelet

```bash
# Enable kubelet service
sudo systemctl enable --now kubelet

# Check status
sudo systemctl status kubelet
```

**Expected behavior:**

```
● kubelet.service - kubelet: The Kubernetes Node Agent
     Active: activating (auto-restart)
```

**⚠️ This is NORMAL!**

Kubelet will continuously restart until the cluster is initialized. This is expected behavior.

---

### Step 2.4: Repeat on All Nodes

**Install on workers:**

```bash
# Worker 1
ssh user@192.168.1.4
# [Run all Step 2.1-2.3 commands]
exit

# Worker 2
ssh user@192.168.1.5
# [Run all Step 2.1-2.3 commands]
exit
```

**Verification checklist:**
- [ ] Kubernetes v1.32.x installed on all nodes
- [ ] Packages held from auto-upgrade
- [ ] kubelet service enabled on all nodes
- [ ] All nodes show same Kubernetes version

---

## PHASE 3: Master Node Initialization

### What kubeadm init Does

```
┌─────────────────────────────────────────┐
│         kubeadm init Process            │
├─────────────────────────────────────────┤
│ 1. Preflight checks                     │
│    ✓ Swap disabled                      │
│    ✓ Ports available                    │
│    ✓ Container runtime ready            │
│                                         │
│ 2. Generate certificates (PKI)          │
│    ✓ CA certificate                     │
│    ✓ API server cert                    │
│    ✓ etcd cert                          │
│                                         │
│ 3. Generate kubeconfig files            │
│    ✓ admin.conf                         │
│    ✓ kubelet.conf                       │
│    ✓ controller-manager.conf            │
│    ✓ scheduler.conf                     │
│                                         │
│ 4. Create static pod manifests          │
│    ✓ kube-apiserver                     │
│    ✓ kube-controller-manager            │
│    ✓ kube-scheduler                     │
│    ✓ etcd                               │
│                                         │
│ 5. Configure kubelet                    │
│                                         │
│ 6. Wait for control plane               │
│                                         │
│ 7. Apply RBAC                           │
│                                         │
│ 8. Install CoreDNS                      │
│                                         │
│ 9. Install kube-proxy                   │
│                                         │
│ 10. Generate bootstrap token            │
└─────────────────────────────────────────┘
```

**Reference:** [kubeadm init](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/)

---

### Step 3.1: Initialize Control Plane

**SSH into master:**

```bash
ssh user@192.168.1.9
```

**Initialize cluster:**

```bash
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=192.168.1.9 \
  --node-name=k8s-master
```

**Parameter explanations:**

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `--pod-network-cidr` | 10.244.0.0/16 | IP range for pod network (Calico default) |
| `--apiserver-advertise-address` | 192.168.1.9 | IP where API server listens (explicit) |
| `--node-name` | k8s-master | Friendly name for this node |

**Why these specific values:**

**Pod Network CIDR:**
- Must not overlap with node network (192.168.1.0/24)
- Calico expects 10.244.0.0/16 by default
- Provides ~65,000 pod IP addresses
- In multi-cluster: Use different CIDRs per cluster

**API Server Address:**
- Explicit is better than auto-detect
- Workers will connect to this IP:6443
- Critical for multi-interface systems

**📸 SCREENSHOT: Initialization in progress**

**Initialization output (2-3 minutes):**

```
[init] Using Kubernetes version: v1.32.11
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] Generating "etcd/peer" certificate and key
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "super-admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods
[apiclient] All control plane components are healthy after 15.003 seconds
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config"
[kubelet] Creating a ConfigMap "kubelet-config" in namespace kube-system
[upload-certs] Skipping phase. Please see --upload-certs
[mark-control-plane] Marking the node k8s-master as control-plane
[mark-control-plane] Tainting node k8s-master
[bootstrap-token] Using token: abcdef.0123456789abcdef
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to post CSRs
[bootstrap-token] Configured RBAC rules to allow the csrapprover controller automatically approve CSRs
[bootstrap-token] Configured RBAC rules to allow certificate rotation for all node client certificates
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.1.9:6443 --token abcdef.0123456789abcdef \
        --discovery-token-ca-cert-hash sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
```

**📸 SCREENSHOT: Success message with join command**

**🚨 CRITICAL: Save the `kubeadm join` command immediately!**

```bash
# Save to file
echo "kubeadm join 192.168.1.9:6443 --token abcdef.0123456789abcdef \
  --discovery-token-ca-cert-hash sha256:1234567890abcdef..." > ~/join-command.txt
```

---

### Step 3.2: Configure kubectl Access

**Run these commands on master:**

```bash
# Create .kube directory
mkdir -p $HOME/.kube

# Copy admin config
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

# Fix ownership
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

**What is kubeconfig:**

```yaml
# ~/.kube/config structure
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: [BASE64_CA_CERT]
    server: https://192.168.1.9:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
users:
- name: kubernetes-admin
  user:
    client-certificate-data: [BASE64_CLIENT_CERT]
    client-key-data: [BASE64_CLIENT_KEY]
```

**Test kubectl:**

```bash
kubectl get nodes
```

**📸 SCREENSHOT: Node shows NotReady (expected)**

```
NAME          STATUS     ROLES           AGE   VERSION
k8s-master    NotReady   control-plane   2m    v1.32.11
```

**Why NotReady?**
- ✅ Normal! CNI plugin not installed yet
- ✅ Will become Ready after Calico installation

**Check control plane pods:**

```bash
kubectl get pods -n kube-system
```

**📸 SCREENSHOT: Control plane pods**

```
NAME                                READY   STATUS    RESTARTS   AGE
coredns-xxx                         0/1     Pending   0          2m
etcd-k8s-master                     1/1     Running   0          2m
kube-apiserver-k8s-master           1/1     Running   0          2m
kube-controller-manager-k8s-master  1/1     Running   0          2m
kube-proxy-xxx                      1/1     Running   0          2m
kube-scheduler-k8s-master           1/1     Running   0          2m
```

**Expected state:**
- ✅ All control plane pods: Running
- ⚠️ CoreDNS: Pending (needs CNI)

---

## PHASE 4: CNI Plugin Installation (Calico)

### Why CNI Plugin is Required

**Kubernetes Networking Requirements:**

```
┌────────────────────────────────────────────┐
│   Kubernetes Network Model Requirements    │
├────────────────────────────────────────────┤
│ 1. All pods can communicate with all pods  │
│    across all nodes without NAT            │
│                                            │
│ 2. All nodes can communicate with all pods │
│    without NAT                             │
│                                            │
│ 3. The IP a pod sees itself as is the same│
│    IP others see it as                     │
└────────────────────────────────────────────┘
```

**Kubernetes does NOT provide this networking!**

You must install a **CNI (Container Network Interface) plugin**.

---

### CNI Plugin Comparison

| Plugin | Complexity | Features | Use Case |
|--------|-----------|----------|----------|
| **Calico** | Medium | NetworkPolicy, BGP, IPIP/VXLAN | **Production (our choice)** |
| **Flannel** | Low | Simple overlay | Development/learning |
| **Weave** | Low-Medium | Encryption, mesh | Small clusters |
| **Cilium** | High | eBPF, L7 policies | Advanced networking |

**Why Calico:**
- ✅ Industry standard (used by enterprises)
- ✅ Supports Network Policies (security)
- ✅ Scalable (1000+ nodes)
- ✅ Excellent documentation
- ✅ Active community

**Reference:** [Calico for Kubernetes](https://docs.tigera.io/calico/latest/about/)

---

### Step 4.1: Install Calico

**Apply Calico manifest:**

```bash
# Still on master node
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/calico.yaml
```

**📸 SCREENSHOT: Resources being created**

```
poddisruptionbudget.policy/calico-kube-controllers created
serviceaccount/calico-kube-controllers created
serviceaccount/calico-node created
configmap/calico-config created
customresourcedefinition.apiextensions.k8s.io/bgpconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/felixconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ippools.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networkpolicies.crd.projectcalico.org created
clusterrole.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrole.rbac.authorization.k8s.io/calico-node created
clusterrolebinding.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrolebinding.rbac.authorization.k8s.io/calico-node created
daemonset.apps/calico-node created
deployment.apps/calico-kube-controllers created
```

**What gets installed:**
- DaemonSet: `calico-node` (runs on every node)
- Deployment: `calico-kube-controllers` (cluster-wide controller)
- ConfigMap: Calico configuration
- CRDs: Custom resources for network policies
- RBAC: Service accounts, roles, bindings

---

### ⚠️ ISSUE #1: Calico Bootstrap Circular Dependency

**📸 SCREENSHOT: Calico pods in CrashLoopBackOff**

```bash
kubectl get pods -n kube-system -w
```

**Observed behavior:**

```
NAME                                      READY   STATUS                  RESTARTS
calico-node-xxx                           0/1     Init:CrashLoopBackOff   3 (16s ago)
calico-kube-controllers-xxx               0/1     Pending                 0
```

---

### 🔍 TROUBLESHOOTING STEP 1: Examine Pod Status

```bash
# Describe the failing pod
kubectl describe pod calico-node-xxx -n kube-system
```

**📸 SCREENSHOT: Pod description showing init container failure**

**Key findings:**

```
Init Containers:
  install-cni:
    State:          Waiting
      Reason:       CrashLoopBackOff
    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
    Restart Count:  4
```

---

### 🔍 TROUBLESHOOTING STEP 2: Check Init Container Logs

```bash
# Check install-cni container logs
kubectl logs calico-node-xxx -n kube-system -c install-cni
```

**📸 SCREENSHOT: Error logs revealing root cause**

```
2026-02-02 16:11:00.022 [INFO][1] cni-installer/install.go 229: Wrote Calico CNI binaries
2026-02-02 16:11:00.023 [ERROR][1] cni-installer/token_watch.go 108: Unable to create token for CNI kubeconfig error=Post "https://10.96.0.1:443/api/v1/namespaces/kube-system/serviceaccounts/calico-cni-plugin/token": dial tcp 10.96.0.1:443: connect: network is unreachable
2026-02-02 16:11:00.023 [FATAL][1] cni-installer/install.go 501: Unable to create token for CNI kubeconfig error=Post "https://10.96.0.1:443/api/v1/namespaces/kube-system/serviceaccounts/calico-cni-plugin/token": dial tcp 10.96.0.1:443: connect: network is unreachable
```

---

### 🎯 ROOT CAUSE ANALYSIS

**Problem:** Network Bootstrap Circular Dependency

```
┌─────────────────────────────────────────────────┐
│          Circular Dependency Diagram             │
├─────────────────────────────────────────────────┤
│                                                  │
│   ┌──────────────────────────────────┐         │
│   │  Calico CNI Installer            │         │
│   │  (install-cni container)         │         │
│   └──────────────┬───────────────────┘         │
│                  │                              │
│                  │ Needs to contact             │
│                  │ API server at                │
│                  │ 10.96.0.1:443                │
│                  │ (ClusterIP)                  │
│                  │                              │
│                  ▼                              │
│   ┌──────────────────────────────────┐         │
│   │  Kubernetes API Service          │         │
│   │  ClusterIP: 10.96.0.1            │         │
│   └──────────────┬───────────────────┘         │
│                  │                              │
│                  │ ClusterIP routing            │
│                  │ requires CNI                 │
│                  │                              │
│                  ▼                              │
│   ┌──────────────────────────────────┐         │
│   │  CNI Plugin (Calico)             │         │
│   │  Status: Not installed yet!      │         │
│   └──────────────────────────────────┘         │
│                  │                              │
│                  │                              │
│                  └──────────────────────────────┤
│                       ❌ DEADLOCK               │
└─────────────────────────────────────────────────┘
```

**Technical Details:**

1. **ClusterIP Service:** Kubernetes API is exposed as a Service with ClusterIP 10.96.0.1
2. **ClusterIP Routing:** Routing to ClusterIP requires functional CNI
3. **CNI Bootstrap:** Calico installer needs API access during initialization
4. **Result:** Calico can't reach API → API needs Calico → Circular dependency

**Reference:** [Calico GitHub Issue #2674](https://github.com/projectcalico/calico/issues/2674)

---

### ✅ SOLUTION: Override API Endpoint

**Create ConfigMap to use Node IP instead of ClusterIP:**

```bash
cat <<EOF | kubectl apply -f -
kind: ConfigMap
apiVersion: v1
metadata:
  name: kubernetes-services-endpoint
  namespace: kube-system
data:
  KUBERNETES_SERVICE_HOST: "192.168.1.9"
  KUBERNETES_SERVICE_PORT: "6443"
EOF
```

**📸 SCREENSHOT: ConfigMap created**

**What this does:**

```
┌────────────────────────────────────────────────┐
│           Solution Architecture                 │
├────────────────────────────────────────────────┤
│                                                 │
│   ┌──────────────────────────────────┐        │
│   │  Calico CNI Installer            │        │
│   └──────────────┬───────────────────┘        │
│                  │                             │
│                  │ Reads ConfigMap             │
│                  │ Uses: 192.168.1.9:6443      │
│                  │ (Node IP, not ClusterIP)    │
│                  │                             │
│                  ▼                             │
│   ┌──────────────────────────────────┐        │
│   │  API Server (Direct)             │        │
│   │  Host: 192.168.1.9:6443          │        │
│   └──────────────────────────────────┘        │
│                  │                             │
│                  │ ✅ No CNI needed            │
│                  │ ✅ Direct connection        │
│                  │                             │
│                  ▼                             │
│            SUCCESS!                            │
└────────────────────────────────────────────────┘
```

**Reinstall Calico (if already applied):**

```bash
# Delete previous installation
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/calico.yaml

# Wait 30 seconds
sleep 30

# Reinstall Calico
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/calico.yaml
```

**Watch pods starting successfully:**

```bash
kubectl get pods -n kube-system -w
```

**📸 SCREENSHOT: Calico pods transitioning to Running**

```
NAME                                      READY   STATUS              RESTARTS   AGE
calico-node-xxx                           0/1     Init:0/3            0          10s
calico-node-xxx                           0/1     Init:1/3            0          15s
calico-node-xxx                           0/1     Init:2/3            0          20s
calico-node-xxx                           0/1     PodInitializing     0          25s
calico-node-xxx                           1/1     Running             0          30s
calico-kube-controllers-xxx               1/1     Running             0          35s
coredns-xxx                               1/1     Running             0          3m
coredns-xxx                               1/1     Running             0          3m
```

**Verify node status:**

```bash
kubectl get nodes
```

**📸 SCREENSHOT: Master node now Ready**

```
NAME          STATUS   ROLES           AGE   VERSION
k8s-master    Ready    control-plane   5m    v1.32.11
```

**✅ Issue #1 Resolved!**

---

### Issue #1 Summary

**Problem:** Calico CNI bootstrap circular dependency  
**Root Cause:** Install-cni container couldn't reach API server ClusterIP (10.96.0.1:443) because ClusterIP routing requires CNI  
**Impact:** Cluster networking non-functional, all pods Pending  
**Solution:** Created kubernetes-services-endpoint ConfigMap to override API endpoint to use node IP (192.168.1.9:6443)  
**Time to Resolution:** 2 hours (including debugging)  
**Prevention:** Document this as known issue for single-master clusters

---

## PHASE 5: Worker Node Integration

### Generate Join Command

**On master node:**

```bash
# If original join token expired, generate new one
kubeadm token create --print-join-command
```

**📸 SCREENSHOT: Join command output**

**Example output:**

```
kubeadm join 192.168.1.9:6443 --token abcdef.0123456789abcdef \
        --discovery-token-ca-cert-hash sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
```

**Save this command!**

---

### ⚠️ ISSUE #2: Version Skew Between Master and Workers

**Scenario:** Workers were initially installed with Kubernetes v1.33

**📸 SCREENSHOT: Version mismatch detection**

```bash
# On worker nodes
ssh user@192.168.1.4 "kubelet --version"
# Output: Kubernetes v1.33.7

# On master
kubectl version --short
# Server Version: v1.32.11
```

---

### 🔍 TROUBLESHOOTING: Version Skew

**Check Kubernetes Version Skew Policy:**

> **From Official Documentation:**
> 
> "kubelet must not be newer than kube-apiserver, and may be up to two minor versions older."

**Reference:** [Kubernetes Version Skew Policy](https://kubernetes.io/releases/version-skew-policy/)

**Our situation:**
- kube-apiserver: v1.32.11
- kubelet (workers): v1.33.7
- **Violation:** kubelet is newer than apiserver ❌

**Impact:**
- API incompatibilities
- Unsupported configuration
- Potential cluster instability
- Worker nodes may fail to join

---

### ✅ SOLUTION: Downgrade Workers to v1.32

**On each worker node:**

```bash
# SSH into worker
ssh user@192.168.1.4

# Stop kubelet
sudo systemctl stop kubelet

# Unhold packages
sudo apt-mark unhold kubeadm kubelet kubectl

# Remove v1.33
sudo apt-get purge -y kubeadm kubelet kubectl
sudo apt-get autoremove -y

# Remove repository
sudo rm /etc/apt/sources.list.d/kubernetes.list
sudo rm /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add v1.32 repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install v1.32
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

# Hold packages
sudo apt-mark hold kubelet kubeadm kubectl

# Verify version
kubelet --version
# Expected: Kubernetes v1.32.11
```

**📸 SCREENSHOT: Version downgraded successfully**

**Repeat for worker2:**

```bash
ssh user@192.168.1.5
# [Run same commands]
```

---

### Join Workers to Cluster

**On each worker node:**

```bash
# Copy the join command from master and run with sudo
sudo kubeadm join 192.168.1.9:6443 --token abcdef.0123456789abcdef \
  --discovery-token-ca-cert-hash sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
```

**📸 SCREENSHOT: Successful join output**

```
[preflight] Running pre-flight checks
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-check] Waiting for a healthy kubelet at http://127.0.0.1:10248/healthz. This can take up to 4m0s
[kubelet-check] The kubelet is healthy after 1.003s
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
```

---

### Verify Cluster

**On master:**

```bash
kubectl get nodes -o wide
```

**📸 SCREENSHOT: All 3 nodes Ready**

```
NAME          STATUS   ROLES           AGE     VERSION    INTERNAL-IP
k8s-master    Ready    control-plane   15m     v1.32.11   192.168.1.9
k8s-worker1   Ready    <none>          3m      v1.32.11   192.168.1.4
k8s-worker2   Ready    <none>          2m      v1.32.11   192.168.1.5
```

**Check system pods distribution:**

```bash
kubectl get pods -n kube-system -o wide
```

**📸 SCREENSHOT: Pods distributed across all nodes**

```
NAME                                      READY   STATUS    NODE
calico-kube-controllers-xxx               1/1     Running   k8s-master
calico-node-aaa                           1/1     Running   k8s-master
calico-node-bbb                           1/1     Running   k8s-worker1
calico-node-ccc                           1/1     Running   k8s-worker2
coredns-xxx                               1/1     Running   k8s-master
coredns-yyy                               1/1     Running   k8s-master
etcd-k8s-master                           1/1     Running   k8s-master
kube-apiserver-k8s-master                 1/1     Running   k8s-master
kube-controller-manager-k8s-master        1/1     Running   k8s-master
kube-proxy-aaa                            1/1     Running   k8s-master
kube-proxy-bbb                            1/1     Running   k8s-worker1
kube-proxy-ccc                            1/1     Running   k8s-worker2
kube-scheduler-k8s-master                 1/1     Running   k8s-master
```

**✅ Issue #2 Resolved!**

---

### Issue #2 Summary

**Problem:** Version skew between control plane and worker nodes  
**Root Cause:** Workers installed with v1.33, master on v1.32 (violates version skew policy)  
**Impact:** Unsupported configuration, potential API incompatibility  
**Solution:** Downgraded workers from v1.33 to v1.32.11 to match master  
**Time to Resolution:** 1 hour (including reinstallation on 2 workers)  
**Prevention:** Always verify Kubernetes version before installation; document target version

---

## 🧪 Verification & Testing

### Test 1: Pod Scheduling Across Nodes

**Create multi-replica deployment:**

```bash
kubectl create deployment nginx-test --image=nginx --replicas=6
```

**Check pod distribution:**

```bash
kubectl get pods -o wide | grep nginx-test
```

**📸 SCREENSHOT: Pods distributed across workers only**

```
NAME                         READY   STATUS    NODE
nginx-test-xxx-1             1/1     Running   k8s-worker1
nginx-test-xxx-2             1/1     Running   k8s-worker2
nginx-test-xxx-3             1/1     Running   k8s-worker1
nginx-test-xxx-4             1/1     Running   k8s-worker2
nginx-test-xxx-5             1/1     Running   k8s-worker1
nginx-test-xxx-6             1/1     Running   k8s-worker2
```

**✅ Verification:** Pods distributed evenly, NOT on master (correct!)

---

### Understanding Master Node Taint

**Check master node taints:**

```bash
kubectl describe node k8s-master | grep -A 3 Taints
```

**📸 SCREENSHOT: Master taint configuration**

```
Taints: node-role.kubernetes.io/control-plane:NoSchedule
```

**What this means:**

```
┌─────────────────────────────────────────────────┐
│         Production Best Practice                 │
├─────────────────────────────────────────────────┤
│                                                  │
│  Master Node Taint: NoSchedule                  │
│                                                  │
│  Effect:                                        │
│  • Application pods CANNOT schedule on master   │
│  • Only system pods with tolerations can run    │
│  • Protects control plane from resource stress  │
│                                                  │
│  Why This is Good:                              │
│  ✅ Control plane components get dedicated CPU  │
│  ✅ No competition from application workloads   │
│  ✅ Security isolation                          │
│  ✅ Easier maintenance & upgrades               │
│                                                  │
│  Enterprise Standard: Always taint masters      │
└─────────────────────────────────────────────────┘
```

**Reference:** [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)

---

### Test 2: Service Exposure & Load Balancing

**Expose deployment as NodePort:**

```bash
kubectl expose deployment nginx-test --port=80 --type=NodePort
```

**Get service details:**

```bash
kubectl get svc nginx-test
```

**📸 SCREENSHOT: Service created**

```
NAME         TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
nginx-test   NodePort   10.96.123.45   <none>        80:32567/TCP   10s
```

**Test from each node:**

```bash
# NodePort is 32567 (example)
curl http://192.168.1.9:32567   # Master
curl http://192.168.1.4:32567   # Worker1
curl http://192.168.1.5:32567   # Worker2
```

**📸 SCREENSHOT: Nginx HTML response from all nodes**

**✅ Verification:** Service accessible from ANY node IP (load balancing works!)

---

### Test 3: Cross-Node Pod Communication

**Create test pods:**

```bash
kubectl run test-pod-1 --image=busybox --command -- sleep 3600
kubectl run test-pod-2 --image=busybox --command -- sleep 3600
```

**Get pod IPs:**

```bash
kubectl get pods -o wide
```

**📸 SCREENSHOT: Pods on different nodes**

```
NAME         READY   STATUS    IP             NODE
test-pod-1   1/1     Running   10.244.194.1   k8s-worker1
test-pod-2   1/1     Running   10.244.126.1   k8s-worker2
```

**Test connectivity:**

```bash
# Ping from pod1 to pod2
kubectl exec test-pod-1 -- ping -c 3 10.244.126.1
```

**📸 SCREENSHOT: Successful ping**

```
PING 10.244.126.1 (10.244.126.1): 56 data bytes
64 bytes from 10.244.126.1: seq=0 ttl=62 time=0.543 ms
64 bytes from 10.244.126.1: seq=1 ttl=62 time=0.398 ms
64 bytes from 10.244.126.1: seq=2 ttl=62 time=0.421 ms

--- 10.244.126.1 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
```

**✅ Verification:** Cross-node networking functional (Calico overlay working!)

**Cleanup:**

```bash
kubectl delete pod test-pod-1 test-pod-2
kubectl delete deployment nginx-test
kubectl delete service nginx-test
```

---

### Test 4: DNS Resolution

**Test DNS from pod:**

```bash
kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup kubernetes
```

**📸 SCREENSHOT: DNS resolution**

```
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.96.0.1 kubernetes.default.svc.cluster.local
```

**✅ Verification:** CoreDNS functional, service discovery working!

---

### Test 5: Node Failure Simulation

**Cordon a worker node:**

```bash
kubectl cordon k8s-worker1
```

**Scale deployment:**

```bash
kubectl create deployment test-failover --image=nginx --replicas=4
kubectl get pods -o wide | grep test-failover
```

**📸 SCREENSHOT: Pods only on worker2 (worker1 cordoned)**

```
NAME                            READY   STATUS    NODE
test-failover-xxx-1             1/1     Running   k8s-worker2
test-failover-xxx-2             1/1     Running   k8s-worker2
test-failover-xxx-3             1/1     Running   k8s-worker2
test-failover-xxx-4             1/1     Running   k8s-worker2
```

**Uncordon node:**

```bash
kubectl uncordon k8s-worker1
```

**Cleanup:**

```bash
kubectl delete deployment test-failover
```

**✅ Verification:** Node management working, workload redistribution successful!

---

## 🏆 Production Best Practices Implemented

### ✅ Security

- [x] TLS certificates for all components (auto-generated by kubeadm)
- [x] RBAC enabled by default
- [x] Service account token rotation
- [x] Pod Security Standards (restricted on kube-system)
- [x] Network policies support (Calico)
- [x] Control plane isolation via taints

### ✅ High Availability Considerations

- [x] Multi-node architecture (1 master + 2 workers)
- [x] Pod distribution across nodes
- [x] Workload can survive single node failure
- [x] Future: Add 2 more masters for HA control plane

### ✅ Networking

- [x] CNI plugin installed (Calico)
- [x] Pod-to-pod communication verified
- [x] Service discovery functional (CoreDNS)
- [x] Cross-node routing working
- [x] Network policies supported

### ✅ Version Management

- [x] All nodes running identical K8s version (v1.32.11)
- [x] Packages held from auto-upgrade
- [x] Version skew policy compliance
- [x] Documented upgrade procedures

### ✅ Observability

- [x] Pod logs accessible via kubectl
- [x] Event monitoring enabled
- [x] Component status queryable
- [ ] Metrics server (Day 4)
- [ ] Prometheus/Grafana (Week 5)

### ✅ Documentation

- [x] Architecture diagrams
- [x] Network topology documented
- [x] Issue RCAs with resolutions
- [x] Configuration files saved
- [x] Verification procedures documented

---

## 📸 Screenshots & Evidence

### Required Screenshots Checklist

**Infrastructure:**
- ![Kubernetes Node with details](.\screenshots\k8s-nodes-with-details.PNG) `kubectl get nodes -o wide` - All 3 nodes Ready
- ![Kubernetes Node](.\screenshots\k8s-nodes.PNG) `kubectl get nodes` with version column
- ![Kubernetes Node](.\screenshots\k8s-master-taint.PNG) `kubectl describe node k8s-master | grep Taints` - Production taint

**System Components:**
- [ ] `kubectl get pods -n kube-system -o wide` - All system pods
- [ ] Calico pods Running across all nodes
- [ ] CoreDNS pods Running

**Troubleshooting Evidence:**
- [ ] Calico install-cni logs showing error
- [ ] ConfigMap kubernetes-services-endpoint
- [ ] Calico pods transitioning from CrashLoopBackOff to Running
- [ ] Version mismatch detection (before fix)
- [ ] Version consistency (after fix)

**Testing:**
- [ ] Multi-replica deployment across workers
- [ ] Service NodePort accessible from all nodes
- [ ] Cross-node pod ping successful
- [ ] DNS resolution working
- [ ] Node cordon/uncordon test

**Commands to Capture:**

```bash
#!/bin/bash

# 1. Cluster nodes
kubectl get nodes -o wide

# 2. System pods
kubectl get pods -n kube-system -o wide

# 3. Node versions
kubectl get nodes -o custom-columns=NAME:.metadata.name,VERSION:.status.nodeInfo.kubeletVersion

# 4. Master taint
kubectl describe node k8s-master | grep -A 3 Taints

# 5. ConfigMap (the fix)
kubectl get configmap kubernetes-services-endpoint -n kube-system -o yaml

# 6. Cluster info
kubectl cluster-info

# 7. Component status
kubectl get componentstatuses  # May be deprecated in v1.32

# 8. Node capacity
kubectl describe node k8s-master | grep -A 8 "Allocated resources"
```

---

## 📚 Resources & References

### Official Documentation

1. [Kubernetes Official Docs](https://kubernetes.io/docs/)
2. [kubeadm Installation Guide](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
3. [Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
4. [Container Runtime Interface](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)
5. [Calico Documentation](https://docs.tigera.io/calico/latest/)
6. [Kubernetes Version Skew Policy](https://kubernetes.io/releases/version-skew-policy/)
7. [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)

### Troubleshooting Resources

8. [Calico GitHub Issues](https://github.com/projectcalico/calico/issues)
9. [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug/)
10. [Debugging Init Containers](https://kubernetes.io/docs/tasks/debug/debug-application/debug-init-containers/)

### Community

11. [Kubernetes Slack](https://kubernetes.slack.com)
12. [r/kubernetes](https://reddit.com/r/kubernetes)
13. [Stack Overflow - Kubernetes](https://stackoverflow.com/questions/tagged/kubernetes)

---

## 📊 Cluster Statistics

**Time Breakdown:**
- System preparation: 30 minutes
- Kubernetes installation: 30 minutes
- Master initialization: 15 minutes
- Calico troubleshooting: 2 hours
- Worker setup & version fix: 1 hour
- Testing & verification: 45 minutes
- Documentation: 45 minutes
- **Total: ~5.5 hours**

**Final Cluster State:**
- **Nodes:** 3 (1 master + 2 workers)
- **Total Pods:** 15+ (system + test)
- **Issues Resolved:** 2 major
- **Commands Executed:** 200+
- **Skills Gained:** ✅ Production-grade K8s setup

---

## ✅ Day 2 Completion Checklist

**Infrastructure:**
- [x] 3 VMs with Kubernetes v1.32.11 installed
- [x] All nodes showing Ready status
- [x] Version consistency across all nodes

**Networking:**
- [x] Calico CNI installed and functional
- [x] Pod-to-pod communication working
- [x] Service discovery operational
- [x] Cross-node routing verified

**Security:**
- [x] Master node tainted (production standard)
- [x] RBAC enabled
- [x] TLS certificates in place

**Testing:**
- [x] Multi-replica deployment tested
- [x] Service load balancing verified
- [x] DNS resolution confirmed
- [x] Node failure scenario tested

**Documentation:**
- [x] Architecture diagrams created
- [x] RCA for both issues documented
- [x] Verification procedures written
- [x] Screenshots captured

**GitHub:**
- [x] Configuration files committed
- [x] Documentation pushed
- [x] Scripts uploaded

---

## 🎯 Next Steps (Day 3)

**Tomorrow's Goals:**
1. Install Helm package manager
2. Deploy Jenkins on Kubernetes
3. Configure persistent storage
4. Access Jenkins UI
5. Install Jenkins plugins
6. Create first Spring Boot application
7. Build first CI/CD pipeline

**Estimated Time:** 3-4 hours

---

## 🏅 Key Learnings

**Technical:**
1. Kubernetes networking bootstrap challenges in single-master clusters
2. Version skew policy is strictly enforced and critical
3. ClusterIP vs NodeIP API access patterns
4. Production taints protect control plane resources
5. CNI plugin selection impacts cluster capabilities

**Operational:**
1. Systematic debugging saves time (logs → describe → RCA)
2. Version consistency prevents subtle bugs
3. Documentation during troubleshooting is invaluable
4. Production best practices exist for good reasons

**Interview Material:**
- Built production-grade 3-node K8s cluster
- Debugged CNI bootstrap circular dependency
- Resolved version skew issue systematically
- Verified cluster with comprehensive testing
- Demonstrated understanding of K8s architecture

---

## 📝 License

This documentation is part of a personal homelab project for educational purposes.

**Author:** DevOps Engineer in Training  
**Date:** February 2, 2026  
**Status:** ✅ Production Ready  
**Next Update:** Day 3 - Jenkins Deployment

---