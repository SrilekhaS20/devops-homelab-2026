# DevOps Homelab 2026

Personal homelab simulating enterprise-grade DevOps environment on limited hardware (16 GB PC + 3 Ubuntu VMs).

**Goal**: Build production-like experience (CI/CD, IaC, monitoring, chaos engineering, scripting, database) to transition to mid-level DevOps/SRE role in 2026.

**Hardware**
- Host: 16 GB RAM laptop
- VM1: Jenkins + Ansible (4 GB)
- VM2: K3s Kubernetes + MySQL (4 GB)
- VM3: Prometheus + Grafana (4 GB)

**Tools**
- Kubernetes: K3s (lightweight)
- CI/CD: Jenkins (primary) + GitHub Actions (parallel)
- IaC & config: Ansible + Terraform (later AWS free tier)
- Database: MySQL
- Monitoring: Prometheus + Grafana
- Scripting: Shell & Python
- AWS simulation: LocalStack + optional free tier

**Progress Log**
- 2026-01-27: VMs created, Ubuntu 24.04 installed, SSH configured - created SSH keys in PC then copied those keys to all 3 VMs
- ...

**Architecture Diagram**

