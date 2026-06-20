#!/bin/bash
set -e  # Exit on any error

# Kubernetes Cluster Recovery Script
# Enterprise-grade automated recovery
# Date: 2026-06-10
# Version: 1.0

echo "╔════════════════════════════════════════════╗"
echo "║  KUBERNETES CLUSTER RECOVERY (IaC)         ║"
echo "║  IP: 192.168.1.10                          ║"
echo "║  Version: v1.28.0                          ║"
echo "╚════════════════════════════════════════════╝"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; exit 1; }

# Verify prerequisites
log_info "Verifying prerequisites..."
command -v kubeadm &> /dev/null || log_error "kubeadm not found"
command -v kubelet &> /dev/null || log_error "kubelet not found"
command -v kubectl &> /dev/null || log_error "kubectl not found"
command -v containerd &> /dev/null || log_error "containerd not found"

# Check if kubeadm-config.yaml exists
[ -f kubeadm-config.yaml ] || log_error "kubeadm-config.yaml not found!"
log_info "kubeadm-config.yaml found"

echo ""
log_info "STEP 1: Stopping services..."
sudo systemctl stop kubelet || true
sudo systemctl stop containerd || true
sleep 5

echo ""
log_info "STEP 2: Resetting cluster..."
sudo kubeadm reset -f --cri-socket=unix:///var/run/containerd/containerd.sock 2>/dev/null || true

echo ""
log_info "STEP 3: Cleaning data directories..."
sudo rm -rf /var/lib/etcd
sudo rm -rf /var/lib/kubelet/pods/*
sudo rm -rf /var/lib/kubelet/plugins_registry 2>/dev/null || true
sudo rm -rf /var/lib/kubelet/plugins 2>/dev/null || true
sudo rm -rf /var/lib/kubelet/pod-resources 2>/dev/null || true

echo ""
log_info "STEP 4: Restarting containerd..."
sudo systemctl start containerd
sleep 5

echo ""
log_info "STEP 5: Restarting kubelet..."
sudo systemctl start kubelet
sleep 5

echo ""
log_info "STEP 6: Initializing cluster from config..."
sudo kubeadm init --config=kubeadm-config.yaml --cri-socket=unix:///var/run/containerd/containerd.sock

echo ""
log_info "STEP 7: Setting up kubeconfig..."
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo ""
log_info "STEP 8: Waiting for cluster to stabilize (60 seconds)..."
sleep 60

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║  VERIFICATION                              ║"
echo "╚════════════════════════════════════════════╝"

echo ""
log_info "Cluster Information:"
kubectl cluster-info || log_error "Failed to get cluster info"

echo ""
log_info "Node Status:"
kubectl get nodes || log_error "Failed to get nodes"

echo ""
log_info "System Pods:"
kubectl get pods -n kube-system || log_error "Failed to get system pods"

echo ""
log_info "Checking API Server..."
kubectl version || log_error "API server not responding"

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║  ✅ CLUSTER RECOVERY COMPLETE!              ║"
echo "╚════════════════════════════════════════════╝"

echo ""
log_info "Next steps:"
echo "  1. Install CNI: kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"
echo "  2. Verify all pods running: kubectl get pods -n kube-system"
echo "  3. Deploy test workload: kubectl run test --image=nginx"

