#!/bin/bash

echo "=========================================="
echo "Regenerating K8s certificates for 192.168.1.10"
echo "=========================================="

# Step 1: Backup
echo "Step 1: Backing up current certificates..."
sudo cp -r /etc/kubernetes/pki /etc/kubernetes/pki.backup
echo "✅ Backup created"

# Step 2: Stop kubelet
echo ""
echo "Step 2: Stopping kubelet..."
sudo systemctl stop kubelet
echo "✅ Kubelet stopped"

# Step 3: Remove old certs
echo ""
echo "Step 3: Removing old API server certificates..."
sudo rm -f /etc/kubernetes/pki/apiserver.crt
sudo rm -f /etc/kubernetes/pki/apiserver.key
echo "✅ Old certificates removed"

# Step 4: Generate new certs
echo ""
echo "Step 4: Generating new API server certificates for 192.168.1.10..."
sudo kubeadm init phase certs apiserver \
  --apiserver-advertise-address=192.168.1.10 \
  --cert-dir=/etc/kubernetes/pki
echo "✅ New certificates generated"

# Step 5: Update API server manifest
echo ""
echo "Step 5: Updating API server manifest..."
sudo sed -i 's/192.168.1.9/192.168.1.10/g' /etc/kubernetes/manifests/kube-apiserver.yaml
echo "✅ Manifest updated"

# Step 6: Start kubelet
echo ""
echo "Step 6: Starting kubelet..."
sudo systemctl start kubelet
echo "✅ Kubelet started"

# Step 7: Wait for API server
echo ""
echo "Step 7: Waiting for API server to come up (30 seconds)..."
sleep 30
echo "✅ Wait complete"

# Step 8: Update kubeconfig
echo ""
echo "Step 8: Updating kubeconfig..."
sed -i 's/192.168.1.9/192.168.1.10/g' ~/.kube/config
echo "✅ kubeconfig updated"

# Step 9: Test
echo ""
echo "Step 9: Testing kubectl..."
kubectl cluster-info
echo ""
kubectl get nodes
echo ""
echo "=========================================="
echo "✅ KUBERNETES CERTIFICATE REGENERATION COMPLETE!"
echo "=========================================="