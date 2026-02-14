# 📝 JENKINS SETUP - COMPLETE README

---

## 🏗️ PROJECT: Production-Ready Jenkins on Docker

**Author:** Srilekha S
**Date:** 8 February 2026
**Environment:** Home Lab / Production
**Status:** ✅ Active & Maintained

---

## 📋 TABLE OF CONTENTS

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Installation](#installation)
5. [Configuration](#configuration)
6. [Verification](#verification)
7. [Backup & Recovery](#backup--recovery)
8. [Troubleshooting](#troubleshooting)
9. [Maintenance](#maintenance)
10. [Screenshots](#screenshots)

---

## 🎯 OVERVIEW

### What is This?

A production-grade Jenkins CI/CD server deployed using Docker with:
- ✅ Persistent storage
- ✅ Auto-restart on failure/reboot
- ✅ Automated backups
- ✅ Resource optimization
- ✅ Security best practices

### Why Docker Instead of Kubernetes?

| Feature | Docker | Kubernetes |
|---------|--------|------------|
| Setup Time | 5 minutes | 2-4 hours |
| Complexity | Low | High |
| Maintenance | Minimal | Ongoing |
| Reliability | High | Requires networking expertise |
| Resource Usage | Low | Medium-High |

**Decision:** Docker provides the best balance for Jenkins master deployment.

---

## 🏛️ ARCHITECTURE

### Infrastructure

```
┌─────────────────────────────────────────────────┐
│  Master Node (192.168.1.9)                      │
│  ┌──────────────────┐  ┌──────────────────┐    │
│  │  Kubernetes      │  │  Jenkins Master  │    │
│  │  Control Plane   │  │  (Docker)        │    │
│  │                  │  │                  │    │
│  │  - API Server    │  │  - Web UI :8080  │    │
│  │  - Scheduler     │  │  - Agents :50000 │    │
│  │  - etcd          │  │  - Persistent    │    │
│  └──────────────────┘  └──────────────────┘    │
└─────────────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
┌───────▼────────┐      ┌──────▼────────┐
│  Worker1       │      │  Worker2      │
│  192.168.1.4   │      │  192.168.1.5  │
│                │      │               │
│  - K8s Pods    │      │  - K8s Pods   │
│  - Jenkins     │      │  - Jenkins    │
│    Build Agents│      │    Build Agents│
└────────────────┘      └───────────────┘
```

### Directory Structure

```
/opt/jenkins_home/          # Persistent data directory
├── jobs/                   # Jenkins jobs
├── plugins/                # Installed plugins
├── users/                  # User accounts
├── secrets/                # Credentials & passwords
├── workspace/              # Build workspaces
├── logs/                   # System logs
└── config.xml             # Main configuration

~/jenkins-backups/          # Automated backups
├── jenkins-backup-20260208-020000.tar.gz
├── jenkins-backup-20260209-020000.tar.gz
└── ...

~/backup-jenkins.sh         # Backup script
~/check-jenkins.sh          # Monitoring script
```

---

## ✅ PREREQUISITES

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 1 core | 2+ cores |
| RAM | 2 GB | 4 GB+ |
| Disk | 10 GB | 20 GB+ |
| OS | Ubuntu 20.04+ | Ubuntu 22.04+ |

### Software Requirements

```bash
# Docker
docker --version
# Docker version 24.0.0+

# System utilities
curl --version
tar --version
```

### Network Requirements

- **Port 8080:** Jenkins Web UI
- **Port 50000:** Jenkins Agent communication
- **Internet:** Required for plugin downloads (initial setup only)

---

## 🚀 INSTALLATION

### Step 1: Verify Docker Installation

```bash
# Check Docker is installed
docker --version

# If not installed:
sudo apt-get update
sudo apt-get install -y docker.io

# Add user to docker group
sudo usermod -aG docker $USER

# Enable Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Verify
sudo systemctl status docker
```

### Step 2: Prepare Storage

```bash
# Create persistent directory
sudo mkdir -p /opt/jenkins_home

# Set correct ownership (Jenkins runs as UID 1000)
sudo chown -R 1000:1000 /opt/jenkins_home

# Set permissions
sudo chmod -R 755 /opt/jenkins_home

# Verify
ls -la /opt/ | grep jenkins
# Expected: drwxr-xr-x ... 1000 1000 ... jenkins_home
```

### Step 3: Deploy Jenkins Container

```bash
# Deploy with production settings
docker run -d \
  --name jenkins \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 50000:50000 \
  -v /opt/jenkins_home:/var/jenkins_home \
  -e JAVA_OPTS="-Xmx2048m -Xms512m" \
  jenkins/jenkins:lts

# Verify deployment
docker ps | grep jenkins
```

**Expected Output:**
```
CONTAINER ID   IMAGE                 STATUS         PORTS
abc123def456   jenkins/jenkins:lts   Up 30 seconds  0.0.0.0:8080->8080/tcp, 0.0.0.0:50000->50000/tcp
```

### Step 4: Wait for Initialization

```bash
# Jenkins takes 60-90 seconds to start
echo "⏳ Waiting for Jenkins to initialize..."
sleep 60

# Monitor startup
docker logs -f jenkins

# Wait for this message:
# "Jenkins is fully up and running"
# Press Ctrl+C to exit logs
```

### Step 5: Retrieve Admin Password

```bash
# Get initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# Example output:
# a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6

# Save this password - you'll need it!
```

---

## ⚙️ CONFIGURATION

### Initial Setup Wizard

1. **Access Jenkins Web UI**
   ```
   URL: http://192.168.1.9:8080
   ```

2. **Unlock Jenkins**
   - Paste the admin password from Step 5
   - Click "Continue"

3. **Customize Jenkins**
   - Select "Install suggested plugins"
   - Wait 5-10 minutes for plugins to install

4. **Create Admin User**
   ```
   Username: Admin
   Password: [your-secure-password]
   Full name: Jenkins Administrator
   Email: admin@gmail.com
   ```

5. **Instance Configuration**
   ```
   Jenkins URL: http://192.168.1.9:8080
   ```
   - Click "Save and Finish"

6. **Start Using Jenkins**
   - Click "Start using Jenkins"

---

## 🎓 ADDITIONAL RESOURCES

### Documentation
- [Official Jenkins Documentation](https://www.jenkins.io/doc/)
- [Docker Documentation](https://docs.docker.com/)
- [Jenkins Pipeline Tutorial](https://www.jenkins.io/doc/book/pipeline/)

### Useful Plugins
- Blue Ocean (Modern UI)
- GitHub Integration
- Docker Pipeline
- Kubernetes Plugin
- Email Extension

### Next Steps
1. Create your first pipeline job
2. Integrate with GitHub/GitLab
3. Set up build agents on worker nodes
4. Configure email notifications
5. Implement security hardening

---

## 📝 CHANGELOG

### Version 1.0 (2026-02-08)
- ✅ Initial production deployment
- ✅ Docker-based installation
- ✅ Automated backup system
- ✅ Monitoring scripts
- ✅ Complete documentation

---

## 👥 MAINTAINER

**Name:** Srilekha Senthilkumar  
**Email:** lekhaconst.1@gmail.com  
**GitHub:** github.com/SrilekhaS20/devops-homelab-2026

---

## 📄 LICENSE

This setup is for educational and production use.  
Jenkins is licensed under MIT License.

---

**🎉 Congratulations! Your Jenkins CI/CD server is production-ready!**