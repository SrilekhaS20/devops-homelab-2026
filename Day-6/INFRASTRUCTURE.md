# Kubernetes Infrastructure as Code

## Overview
This directory contains all Infrastructure as Code (IaC) for the homelab Kubernetes cluster at 192.168.1.10.

## Files

### kubeadm-config.yaml
- **Purpose**: Declarative cluster configuration
- **Used by**: `kubeadm init`
- **Contains**: API server, etcd, kubelet, networking config
- **Version Controlled**: YES (Git)

### cluster-recover.sh
- **Purpose**: Automated cluster recovery script
- **Prerequisites**: kubeadm-config.yaml must exist
- **Usage**: `./cluster-recover.sh`
- **Idempotent**: YES (safe to run multiple times)

### RECOVERY_RUNBOOK.md
- **Purpose**: Step-by-step manual recovery
- **Use when**: Script fails or manual intervention needed
- **Maintenance**: Update after cluster changes

## Cluster Specifications

| Component | Value |
|-----------|-------|
| Kubernetes Version | v1.28.0 |
| API Server IP | 192.168.1.10:6443 |
| Pod Network | 10.244.0.0/16 |
| Service Network | 10.96.0.0/12 |
| Container Runtime | containerd |
| Node Count | 1 (single-node) |
| Storage | /var/lib/etcd |

## Recovery Procedure

### Quick Recovery (recommended)
```bash
cd ~/k8s-disaster-recovery
./cluster-recover.sh
```

### Manual Recovery
1. Follow RECOVERY_RUNBOOK.md
2. Run each step individually
3. Verify after each step

## Maintenance

### After Any Cluster Change
1. Update kubeadm-config.yaml
2. Update RECOVERY_RUNBOOK.md
3. Test recovery script
4. Git commit changes

```bash
git add kubeadm-config.yaml RECOVERY_RUNBOOK.md cluster-recover.sh
git commit -m "Update cluster config: <description>"
```

## Troubleshooting

### API Server not responding
```bash
sudo journalctl -u kubelet -n 50
kubectl describe nodes
```

### etcd not starting
```bash
sudo crictl logs $(sudo crictl ps | grep etcd | awk '{print $1}')
```

### Pod DNS not working
```bash
kubectl get pods -n kube-system | grep coredns
```

