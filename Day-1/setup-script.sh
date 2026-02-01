cat > /tmp/k8s-prep.sh << 'SCRIPT'
#!/bin/bash
set -e

echo "========================================="
echo "Starting K8s preparation..."
echo "Hostname: $(hostname)"
echo "========================================="

# Update system
echo "[1/8] Updating system..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "[2/8] Installing required packages..."
sudo apt install -y curl wget git vim net-tools openssh-server

# Disable swap (CRITICAL for K8s)
echo "[3/8] Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Load kernel modules
echo "[4/8] Creating kernel modules config..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

echo "[5/8] Loading kernel modules..."
sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl
echo "[6/8] Configuring sysctl parameters..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

echo "[7/8] Applying sysctl settings..."
sudo sysctl --system

# Verify configuration
echo "[8/8] Verifying configuration..."
echo ""
echo "✓ Swap status:"
free -h | grep Swap

echo ""
echo "✓ Kernel modules loaded:"
lsmod | grep -E 'overlay|br_netfilter'

echo ""
echo "✓ Sysctl settings:"
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
sysctl net.ipv4.ip_forward

echo ""
echo "========================================="
echo "✅ System preparation complete on $(hostname)!"
echo "========================================="
SCRIPT

chmod +x /tmp/k8s-prep.sh