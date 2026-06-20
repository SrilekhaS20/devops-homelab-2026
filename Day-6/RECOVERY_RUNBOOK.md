# Kubernetes Cluster Recovery Runbook

## Prerequisites
- Ubuntu 24.04 LTS
- containerd installed
- kubeadm, kubelet, kubectl installed
- IP: 192.168.1.10
- 3.8GB RAM minimum
- 40GB disk

## Recovery Steps

### Step 1: Stop All Services
```bash
sudo systemctl stop kubelet
sudo systemctl stop containerd
sleep 5
```

### Step 2: Reset Cluster (destructive!)
```bash
sudo kubeadm reset -f --cri-socket=unix:///var/run/containerd/containerd.sock
sudo rm -rf /var/lib/etcd
sudo rm -rf /var/lib/kubelet/pods/*
```

### Step 3: Restart Services
```bash
sudo systemctl start containerd
sleep 5
sudo systemctl start kubelet
sleep 5
```

### Step 4: Initialize from Config
```bash
sudo kubeadm init --config=kubeadm-config.yaml --cri-socket=unix:///var/run/containerd/containerd.sock
```

### Step 5: Setup kubeconfig
```bash
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Step 6: Verify Cluster
```bash
kubectl cluster-info
kubectl get nodes
kubectl get pods -n kube-system
```

### Step 7: Install CNI (Flannel)
```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

## Verification Checklist
- [ ] API server responding to kubectl
- [ ] All nodes show "Ready" status
- [ ] All system pods in kube-system are "Running"
- [ ] No RBAC errors
- [ ] Can deploy test pod
- [ ] Flannel pods running

## Rollback
If cluster fails to initialize:
1. Run `sudo kubeadm reset -f`
2. Check logs: `sudo journalctl -u kubelet -n 50`
3. Fix issues (IP conflicts, disk space, etc.)
4. Retry `kubeadm init`

## Emergency Contacts
- Kubernetes Docs: https://kubernetes.io/docs/
- TroubleShooting: https://kubernetes.io/docs/tasks/debug-application-cluster/

