# Day 1: VM Setup & System Preparation

**Date:** January 27, 2026  
**Goal:** Prepare 3 VMs for Kubernetes cluster installation  
**Time Required:** 2-3 hours

---

## Pre-requisites Completed ✅

- ✅ 3 VMs created in VirtualBox/VMware
- ✅ Ubuntu 24.04 installed on all VMs
- ✅ SSH keys generated and copied to all VMs
- ✅ Bridge network adapter configured

---

## VM Configuration

| VM | IP Address | Hostname | RAM | vCPU | Disk |
|----|------------|----------|-----|------|------|
| VM1 (Master)  | 192.168.1.9 | k8s-master  | 4GB | 2 | 40GB |
| VM2 (Worker1) | 192.168.1.4 | k8s-worker1 | 4GB | 2 | 40GB |
| VM3 (Worker2) | 192.168.1.5 | k8s-worker2 | 4GB | 2 | 40GB |

---

## Step-by-Step Setup

### **STEP 1: Set Hostnames (5 minutes)**

Run on each VM respectively:

**On VM1 (192.168.1.9):**
```bash
ssh user@192.168.1.9
sudo hostnamectl set-hostname k8s-master
exit
```

**On VM2 (192.168.1.4):**
```bash
ssh user@192.168.1.4
sudo hostnamectl set-hostname k8s-worker1
exit
```

**On VM3 (192.168.1.5):**
```bash
ssh user@192.168.1.5
sudo hostnamectl set-hostname k8s-worker2
exit
```

**Verify hostnames:**
```bash
ssh user@192.168.1.9 "hostname"  # Should return: k8s-master
ssh user@192.168.1.4 "hostname"  # Should return: k8s-worker1
ssh user@192.168.1.5 "hostname"  # Should return: k8s-worker2
```

---

### **STEP 2: Configure /etc/hosts on All VMs (5 minutes)**

**Option A: From your PC (recommended - faster)**

Create hosts file:
```bash
cat > /tmp/k8s-hosts << 'EOF'
192.168.1.9    k8s-master
192.168.1.4    k8s-worker1
192.168.1.5    k8s-worker2
EOF
```

Add to all VMs:
```bash
# Replace 'user' with your actual username
ssh user@192.168.1.9 "sudo tee -a /etc/hosts" < /tmp/k8s-hosts
ssh user@192.168.1.4 "sudo tee -a /etc/hosts" < /tmp/k8s-hosts
ssh user@192.168.1.5 "sudo tee -a /etc/hosts" < /tmp/k8s-hosts
```

**Option B: Manually on each VM**

SSH into each VM and run:
```bash
sudo vim /etc/hosts
```

Add these lines at the end:
```
192.168.1.9    k8s-master
192.168.1.4    k8s-worker1
192.168.1.5    k8s-worker2
```

**Test connectivity:**
```bash
ssh user@192.168.1.9 "ping -c 2 k8s-master"
ssh user@192.168.1.4 "ping -c 2 k8s-worker1"
ssh user@192.168.1.5 "ping -c 2 k8s-worker2"
```

---

### **STEP 3: System Preparation Script (15 minutes)**

This script will:
1. Update the system
2. Install required packages
3. Disable swap (required for Kubernetes)
4. Load kernel modules (overlay, br_netfilter)
5. Configure sysctl parameters for networking

**Create the preparation script on your PC:**

```bash
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
```

**Run on all VMs:**

```bash
# Copy and execute on all 3 VMs (replace 'user' with your username)
for ip in 192.168.1.4 192.168.1.5 192.168.1.9; do
  echo "===== Configuring $ip ====="
  scp /tmp/k8s-prep.sh user@$ip:/tmp/
  ssh user@$ip "bash /tmp/k8s-prep.sh"
  echo ""
done
```

**This will take 5-10 minutes per VM.**

---

### **STEP 4: Verify Configuration (5 minutes)**

**Check on each VM:**

```bash
# Check swap is disabled (should show 0B)
ssh user@192.168.1.4 "free -h | grep Swap"

# Check kernel modules are loaded
ssh user@192.168.1.4 "lsmod | grep br_netfilter"
ssh user@192.168.1.4 "lsmod | grep overlay"

# Check sysctl settings
ssh user@192.168.1.4 "sysctl net.bridge.bridge-nf-call-iptables"
ssh user@192.168.1.4 "sysctl net.ipv4.ip_forward"
```

**Expected output:**
- Swap: `Swap: 0B 0B 0B`
- Modules: Should show module details
- Sysctl: Should show `= 1`

---

### **STEP 5: Configure Static IPs (Optional)**

**Note:** Since you already have working IPs (192.168.1.9, 192.168.1.4, 192.168.1.5), you can skip this if they're already static.

**To make IPs static (if currently DHCP):**

Check your network interface name:
```bash
ssh user@192.168.1.4 "ip a"
# Look for interface like: ens33, ens18, enp0s3, eth0
```

Edit netplan configuration:
```bash
ssh user@192.168.1.4
sudo vim /etc/netplan/50-cloud-init.yaml
```

**Example configuration (adjust interface name):**

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 192.168.1.9/24
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
```

Apply configuration:
```bash
sudo netplan apply
ip addr show
exit
```

**Repeat for other VMs with their respective IPs.**

---

## Verification Checklist

After completing all steps, verify:

- [ ] All 3 VMs have correct hostnames (k8s-master, k8s-worker1, k8s-worker2)
- [ ] All VMs can ping each other by hostname
- [ ] Swap is disabled on all VMs (`free -h` shows 0B)
- [ ] Kernel modules loaded (`lsmod | grep overlay` and `lsmod | grep br_netfilter`)
- [ ] Sysctl parameters configured (`sysctl net.ipv4.ip_forward` shows 1)
- [ ] Passwordless SSH working from your PC to all VMs
- [ ] All packages updated (`apt update && apt upgrade`)

---

## What We've Accomplished Today

✅ **Hostnames configured** on all 3 nodes  
✅ **/etc/hosts configured** for internal name resolution  
✅ **System packages updated**  
✅ **Required tools installed** (curl, wget, git, vim, etc.)  
✅ **Swap disabled** (K8s requirement)  
✅ **Kernel modules loaded** (overlay, br_netfilter)  
✅ **Network settings configured** (sysctl parameters)  
✅ **SSH access verified** from PC to all VMs  

---

## Troubleshooting

### Issue: Can't ping by hostname

```bash
# Check /etc/hosts
cat /etc/hosts

# Make sure these lines exist:
# 192.168.1.9    k8s-master
# 192.168.1.4    k8s-worker1
# 192.168.1.5    k8s-worker2
```

### Issue: Swap still showing as enabled

```bash
# Disable swap immediately
sudo swapoff -a

# Check fstab
cat /etc/fstab | grep swap
# Should be commented out with #

# Verify
free -h
```

### Issue: Kernel modules not loading

```bash
# Load manually
sudo modprobe overlay
sudo modprobe br_netfilter

# Verify
lsmod | grep overlay
lsmod | grep br_netfilter

# Check if module config file exists
cat /etc/modules-load.d/k8s.conf
```

### Issue: sysctl settings not applied

```bash
# Check config file
cat /etc/sysctl.d/k8s.conf

# Apply manually
sudo sysctl --system

# Verify
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.ipv4.ip_forward
```

---

## Files Created

- `/tmp/k8s-hosts` - Hosts entries
- `/tmp/k8s-prep.sh` - System preparation script
- `/etc/modules-load.d/k8s.conf` - Kernel modules configuration (on VMs)
- `/etc/sysctl.d/k8s.conf` - Sysctl parameters (on VMs)

---

## Commands Reference

**Check hostname:**
```bash
hostname
hostnamectl
```

**Check network:**
```bash
ip addr show
ip route
ping -c 2 k8s-master
```

**Check swap:**
```bash
free -h
cat /proc/swaps
```

**Check kernel modules:**
```bash
lsmod | grep overlay
lsmod | grep br_netfilter
```

**Check sysctl:**
```bash
sysctl -a | grep bridge
sysctl net.ipv4.ip_forward
```

---

**Day 1 Status: ✅ COMPLETE**