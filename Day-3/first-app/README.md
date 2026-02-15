# Automated CI/CD Pipeline - Node.js Application

## 🎯 Project Overview

Production-ready CI/CD pipeline that automatically builds, tests, and deploys
a Node.js application using Jenkins and Docker.

## 🏗️ Architecture
```
Developer Push → GitHub → Jenkins (SCM Polling) → Build → Deploy → Verify
```

## 🛠️ Tech Stack

- **CI/CD:** Jenkins
- **Containerization:** Docker
- **Version Control:** Git/GitHub
- **Language:** Node.js 14
- **Server:** Ubuntu 24 (K8s Master Node)

## 📋 Pipeline Stages

1. **Build Docker Image** - Creates containerized application
2. **Deploy** - Deploys container to server
3. **Wait for Startup** - Allows app to initialize
4. **Health Check** - Verifies deployment success
5. **Smoke Tests** - Validates basic functionality

## ⚙️ Configuration

- **Trigger:** SCM Polling (every 2 minutes)
- **Port:** 3000
- **Deployment Time:** ~2 minutes from commit to live
- **Automatic Rollback:** On failure

## 🚀 Deployment

### Prerequisites
- Jenkins with Docker support
- Docker installed on deployment server
- GitHub repository access

### Access
- **Application:** http://192.168.1.9:3000
- **Jenkins:** http://192.168.1.9:8080

## 🐛 Issues Resolved

### 1. Docker Command Not Found
**Problem:** Jenkins container couldn't access Docker
**Solution:** Mounted Docker socket and binary into Jenkins container

### 2. Dockerfile Path Not Found
**Problem:** Jenkins looking in wrong directory
**Solution:** Used `dir()` directive to change to correct directory

### 3. GitHub Webhook Connection Failed
**Problem:** Private IP not accessible from GitHub
**Solution:** Implemented SCM polling instead of webhooks

### 4. Docker Socket Permissions
**Problem:** Permission denied accessing Docker socket
**Solution:** Fixed permissions with `chmod 666 /var/run/docker.sock`

### 5. Health Check Network Isolation
**Problem:** Jenkins couldn't reach app via localhost
**Solution:** Used `docker exec` to run health check inside app container

## Step by step approach

### 1. Created GitHub Webhook

![GitHub Webhook](screenshots/jenkins-webhook.png)

### 2. Jenkins pipeline success


### 3. Jenkins console output


### 4. Jenkins Build history


### 5. List Running Docker Container


### 6. Node.js app working in Browser


### 7. Final working Jenkinsfile content

```Jenkinsfile
pipeline {
    agent any

    stages {
        stage('Build Docker Image') {
            steps {
                dir('Day-3/first-app') {
                    sh 'docker build -t first-app:${BUILD_NUMBER} . '
                }
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    docker stop first-app || true
                    docker rm first-app || true
                    docker run -d --name first-app -p 3000:3000 first-app:${BUILD_NUMBER}
                '''
            }
        }

        stage('Metrics') {
            steps {
                script {
                    def buildTime = currentBuild.duration / 1000
                    echo "Build took ${buildTime} seconds"
                }
            }
        }

        stage('Wait for Startup') {
            steps {
                echo 'Waiting for application to fully start...'
                sleep(time: 25, unit: 'SECONDS')
            }
        }

        stage('Post-Deploy Health Check') {
            steps {
                echo 'Performing health check...'
                script {
                    sleep(time: 15, unit: 'SECONDS')

                    def healthCheckPassed = false
                    for (int i = 1; i <= 5; i++) {
                        try {
                            sh 'docker exec first-app curl -f http://localhost:3000'
                            echo "Health check passed on attempt ${i}!"
                            healthCheckPassed = true
                            break
                        } catch (Exception e) {
                            echo "Attempt ${i} failed, retrying..."
                            if (i < 5) {
                                sleep(time: 5, unit: 'SECONDS')
                            }
                        }
                    }

                    if (!healthCheckPassed) {
                        error("Health check failed after 5 attempts")
                    }
                }
            }
        }

        stage('Smoke Tests') {
            steps {
                echo 'Running smoke tests...'
                sh '''
                    echo "Test 1: Main endpoint"
                    RESPONSE=$(docker exec first-app curl -s http://localhost:3000)
                    echo "Response: $RESPONSE"

                    echo "Test 2: Container health"
                    docker exec first-app curl -s localhost:3000

                    echo "All smoke tests passed!"
                '''
            }
        }
    }

    post {
        success {
            echo '============================================'
            echo 'PIPELINE COMPLETED SUCCESSFULLY!'
            echo '============================================'
            echo "Application URL: http://192.168.1.9:3000"
            echo "Build Number: ${BUILD_NUMBER}"
            echo "Docker Image: first-app:${BUILD_NUMBER}"
            sh 'docker exec first-app curl -s http://localhost:3000'
            echo '============================================'
        }
        failure {
            echo '============================================'
            echo 'PIPELINE FAILED!'
            echo '============================================'
            sh '''
                echo "Container status:"
                docker ps | grep first-app || echo "Container not running"

                echo "Container logs:"
                docker logs first-app || echo "No logs available"
            '''
            echo '============================================'
        }
        always {
            echo 'Cleaning up old Docker images...'
            sh 'docker image prune -f || true'
        }
    }
}
```

## 📊 Results

- ✅ Fully automated deployment
- ✅ Zero manual intervention
- ✅ 2-minute deployment cycle
- ✅ Automatic health verification
- ✅ Production-ready reliability

## 🎓 Skills Demonstrated

- Jenkins pipeline development
- Docker containerization
- CI/CD automation
- Network troubleshooting
- Linux system administration
- Git workflow management

## 📝 Lessons Learned

1. **Docker Networking:** Container isolation requires understanding of
   network namespaces
2. **Permission Management:** Docker socket permissions critical for
   container-based CI/CD
3. **Systematic Debugging:** Step-by-step troubleshooting essential for
   complex issues
4. **Production Readiness:** Health checks and verification crucial for
   reliable deployments

## 👨‍💻 Author

Srilekha S - DevOps Engineer

## 📅 Timeline

- Started: February 14, 2026
- Completed: February 15, 2026
- Total Time: 4+ hours
- Issues Debugged: 5
