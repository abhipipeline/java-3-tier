# Deploy Java Application on Google Cloud Platform 3-Tier Architecture

![GCP Architecture](https://imgur.com/b9iHwVc.png)

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture Overview](#architecture-overview)
3. [Pre-Requisites](#pre-requisites)
4. [Infrastructure Setup](#infrastructure-setup)
   - [VPC and Networking](#vpc-and-networking)
   - [Security Configuration](#security-configuration)
   - [Database Layer](#database-layer)
5. [Application Setup](#application-setup)
   - [Build Environment](#build-environment)
   - [Application Deployment](#application-deployment)
   - [Load Balancing and Auto Scaling](#load-balancing-and-auto-scaling)
6. [Monitoring and Maintenance](#monitoring-and-maintenance)
7. [Security Best Practices](#security-best-practices)
8. [Troubleshooting Guide](#troubleshooting-guide)
9. [Contributing](#contributing)

---

![3-tier Architecture Diagram](https://imgur.com/3XF0tlJ.png)

---

# Project Overview

## Introduction

This project demonstrates the deployment of a production-grade Java web application using Google Cloud Platform's robust 3-tier architecture. The implementation follows cloud-native best practices, ensuring high availability, scalability, and security across all application tiers.

### Key Features

- **High Availability**: Multi-region deployment with automated failover
- **Auto Scaling**: Dynamic resource allocation based on demand
- **Security**: Defense-in-depth approach with multiple security layers
- **Monitoring**: Comprehensive logging and monitoring setup with Cloud Logging and Cloud Monitoring
- **Cost Optimization**: Efficient resource utilization and management

## Architecture Overview

### Infrastructure Components

1. **Presentation Tier (Frontend)**
   - Nginx web servers in Managed Instance Group
   - Public-facing Load Balancer with HTTP(S)
   - Cloud CDN Distribution for static content

2. **Application Tier (Backend)**
   - Apache Tomcat servers in Managed Instance Group
   - Internal Load Balancer
   - Session management with Cloud Memorystore for Redis

3. **Data Tier**
   - Google Cloud SQL for MySQL in High Availability configuration
   - Automated backups and point-in-time recovery
   - Read replicas for read-heavy workloads

### Network Architecture

- **VPC Design**
  - One VPC with multiple subnets
  - Public and private subnets across multiple regions
  - VPC peering for inter-VPC communication (if needed)
  - Cloud NAT for outbound traffic from private subnets

# Pre-Requisites

## Required Accounts and Tools

### 1. Google Cloud Account Setup
- Create a [Google Cloud Account](https://cloud.google.com/free)
- Enable billing for your project
- Install Google Cloud SDK (gcloud CLI)
  ```bash
  # For Linux
  curl https://sdk.cloud.google.com | bash
  exec -l $SHELL

  # For macOS
  brew install --cask google-cloud-sdk

  # Initialize and configure
  gcloud init
  gcloud auth login
  gcloud config set project PROJECT_ID
  ```

### 2. Development Tools
- **Git**: Version control system
  ```bash
  # For Linux
  sudo apt-get update
  sudo apt-get install git

  # For macOS
  brew install git
  ```

### 3. CI/CD Integration
- **SonarCloud Account**
  - Sign up at [SonarCloud](https://sonarcloud.io/)
  - Generate authentication token
  - Configure project settings:
    ```bash
    # Add to pom.xml
    <properties>
        <sonar.projectKey>your_project_key</sonar.projectKey>
        <sonar.organization>your_organization</sonar.organization>
        <sonar.host.url>https://sonarcloud.io</sonar.host.url>
    </properties>
    ```

- **Artifact Registry (Google Cloud)**
  - Enable Artifact Registry API in GCP console
  - Create Maven repository:
    ```bash
    gcloud artifacts repositories create java-repo \
        --repository-format=maven \
        --location=us-central1 \
        --description="Java Maven Repository"
    ```
  - Configure authentication:
    ```xml
    <!-- settings.xml -->
    <servers>
        <server>
            <id>gcp-artifactory</id>
            <username>_json_key_base64</username>
            <password>${env.GCP_ARTIFACT_REGISTRY_PASSWORD}</password>
        </server>
    </servers>
    ```

# Infrastructure Setup

## VPC and Networking

### 1. VPC Creation
```bash
# Create primary VPC
gcloud compute networks create primary-vpc \
    --subnet-mode=custom \
    --bgp-routing-mode=regional

# Create secondary VPC (if needed for multi-VPC setup)
gcloud compute networks create secondary-vpc \
    --subnet-mode=custom \
    --bgp-routing-mode=regional
```

### 2. Subnet Configuration
```bash
# Create public subnet in primary VPC
gcloud compute networks subnets create public-subnet-1 \
    --network=primary-vpc \
    --region=us-central1 \
    --range=192.168.1.0/24 \
    --enable-flow-logs

# Create private subnet in primary VPC
gcloud compute networks subnets create private-subnet-1 \
    --network=primary-vpc \
    --region=us-central1 \
    --range=192.168.2.0/24 \
    --enable-flow-logs
```

### 3. Cloud NAT and Cloud Router Setup
```bash
# Create Cloud Router
gcloud compute routers create primary-router \
    --network=primary-vpc \
    --region=us-central1

# Create Cloud NAT for outbound traffic
gcloud compute routers nats create primary-nat \
    --router=primary-router \
    --region=us-central1 \
    --nat-all-subnet-ip-ranges \
    --auto-allocate-nat-external-ips
```

## Security Configuration

### 1. Firewall Rules
```bash
# Create firewall rule for frontend - allow HTTP/HTTPS
gcloud compute firewall-rules create allow-http-https \
    --network=primary-vpc \
    --allow=tcp:80,tcp:443 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=frontend

# Create firewall rule for backend - internal communication
gcloud compute firewall-rules create allow-backend-internal \
    --network=primary-vpc \
    --allow=tcp:8080 \
    --source-tags=frontend \
    --target-tags=backend

# Create firewall rule for database - allow from backend only
gcloud compute firewall-rules create allow-database \
    --network=primary-vpc \
    --allow=tcp:3306 \
    --source-tags=backend \
    --target-tags=database

# Allow health checks
gcloud compute firewall-rules create allow-health-checks \
    --network=primary-vpc \
    --allow=tcp \
    --source-ranges=35.191.0.0/16,130.211.0.0/22 \
    --target-tags=http-server,https-server
```

### 2. Service Account and IAM Roles
```bash
# Create service account for application
gcloud iam service-accounts create java-app-sa \
    --display-name="Java Application Service Account"

# Grant necessary permissions
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member=serviceAccount:java-app-sa@PROJECT_ID.iam.gserviceaccount.com \
    --role=roles/cloudsql.client

gcloud projects add-iam-policy-binding PROJECT_ID \
    --member=serviceAccount:java-app-sa@PROJECT_ID.iam.gserviceaccount.com \
    --role=roles/storage.objectViewer

gcloud projects add-iam-policy-binding PROJECT_ID \
    --member=serviceAccount:java-app-sa@PROJECT_ID.iam.gserviceaccount.com \
    --role=roles/logging.logWriter

gcloud projects add-iam-policy-binding PROJECT_ID \
    --member=serviceAccount:java-app-sa@PROJECT_ID.iam.gserviceaccount.com \
    --role=roles/monitoring.metricWriter
```

## Database Layer

### 1. Cloud SQL Instance Creation
```bash
# Create MySQL instance with high availability
gcloud sql instances create prod-mysql \
    --database-version=MYSQL_8_0 \
    --tier=db-f1-micro \
    --region=us-central1 \
    --availability-type=REGIONAL \
    --backup-start-time=03:00 \
    --retained-backups-count=30 \
    --enable-bin-log \
    --backup-location=us \
    --network=projects/PROJECT_ID/global/networks/primary-vpc \
    --no-assign-ip
```

### 2. Database Initialization
```bash
# Connect to the instance
gcloud sql connect prod-mysql --user=root

# Or using Cloud SQL Proxy
cloud_sql_proxy -instances=PROJECT_ID:us-central1:prod-mysql=tcp:3306 &

# Connect using MySQL client
mysql -h 127.0.0.1 -u root -p

# Create application database
CREATE DATABASE javaapp;
USE javaapp;

# Create users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

# Create necessary indexes
CREATE INDEX idx_username ON users(username);
CREATE INDEX idx_email ON users(email);

# Create database user
CREATE USER 'appuser'@'%' IDENTIFIED BY 'SecurePassword123!';
GRANT ALL PRIVILEGES ON javaapp.* TO 'appuser'@'%';
FLUSH PRIVILEGES;
```

### 3. Cloud Memorystore for Redis (Session Store)
```bash
gcloud redis instances create primary-redis \
    --size=1 \
    --region=us-central1 \
    --redis-version=6.x \
    --network=projects/PROJECT_ID/global/networks/primary-vpc
```

# Application Setup

## Build Environment

### 1. Maven Configuration
```xml
<!-- pom.xml -->
<project>
    <properties>
        <java.version>11</java.version>
        <spring.version>2.5.12</spring.version>
    </properties>
    
    <dependencies>
        <!-- Spring Boot Web Starter -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        
        <!-- Spring Data JPA -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        
        <!-- MySQL Connector -->
        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
            <scope>runtime</scope>
        </dependency>
        
        <!-- Redis -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-redis</artifactId>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

### 2. Build Process
```bash
# Clean and build project
mvn clean package -DskipTests

# Run tests
mvn test

# Deploy to Artifact Registry
mvn deploy -DaltDeploymentRepository=gcp-artifactory::https://us-central1-maven.pkg.dev/PROJECT_ID/java-repo
```

## Application Deployment

### 1. Create Custom VM Image with Tomcat
```bash
# Create startup script
cat << 'EOF' > startup-script.sh
#!/bin/bash
set -e

# Update system
apt-get update
apt-get install -y openjdk-11-jdk curl wget

# Install Tomcat
cd /opt
wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.70/bin/apache-tomcat-9.0.70.tar.gz
tar -xzf apache-tomcat-9.0.70.tar.gz
mv apache-tomcat-9.0.70 tomcat
useradd -r -d /opt/tomcat -s /sbin/nologin tomcat
chown -R tomcat:tomcat /opt/tomcat

# Create systemd service
cat > /etc/systemd/system/tomcat.service << 'TOMCAT'
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat
Environment=JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true'

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
TOMCAT

systemctl daemon-reload
systemctl enable tomcat
systemctl start tomcat

# Install Cloud Ops Agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
EOF

chmod +x startup-script.sh

# Create image from existing VM or from source image
gcloud compute images create tomcat-image \
    --source-uri=gs://my-bucket/my-image.tar.gz
```

### 2. Nginx Configuration (Frontend)
```nginx
# /etc/nginx/conf.d/app.conf
upstream backend {
    # Internal Load Balancer IP
    server 192.168.2.10:8080;
}

server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        # Serve from Cloud Storage via Cloud CDN
        proxy_pass https://cdn.example.com;
        proxy_cache_key "$scheme$request_method$host$request_uri";
        proxy_cache_valid 200 1h;
    }
}
```

## Load Balancing and Auto Scaling

### 1. Instance Template Configuration
```bash
# Create instance template for frontend
gcloud compute instance-templates create web-server-template \
    --machine-type=e2-medium \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --boot-disk-size=20GB \
    --network-interface=network=primary-vpc,subnet=public-subnet-1,external-ip=pool \
    --metadata-from-file=startup-script=frontend-startup.sh \
    --service-account=java-app-sa@PROJECT_ID.iam.gserviceaccount.com \
    --scopes=cloud-platform \
    --tags=frontend,http-server,https-server

# Create instance template for backend
gcloud compute instance-templates create app-server-template \
    --machine-type=e2-medium \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --boot-disk-size=20GB \
    --network-interface=network=primary-vpc,subnet=private-subnet-1,no-address \
    --metadata-from-file=startup-script=startup-script.sh \
    --service-account=java-app-sa@PROJECT_ID.iam.gserviceaccount.com \
    --scopes=cloud-platform \
    --tags=backend
```

### 2. Managed Instance Groups and Auto Scaling
```bash
# Create managed instance group for frontend
gcloud compute instance-groups managed create web-server-group \
    --base-instance-name=web-server \
    --template=web-server-template \
    --size=2 \
    --region=us-central1

# Set up auto scaling for frontend
gcloud compute instance-groups managed set-autoscaling web-server-group \
    --region=us-central1 \
    --max-num-replicas=6 \
    --min-num-replicas=2 \
    --target-cpu-utilization=0.6

# Create managed instance group for backend
gcloud compute instance-groups managed create app-server-group \
    --base-instance-name=app-server \
    --template=app-server-template \
    --size=2 \
    --region=us-central1

# Set up auto scaling for backend
gcloud compute instance-groups managed set-autoscaling app-server-group \
    --region=us-central1 \
    --max-num-replicas=6 \
    --min-num-replicas=2 \
    --target-cpu-utilization=0.65
```

### 3. Load Balancer Configuration
```bash
# Create health check
gcloud compute health-checks create http frontend-health-check \
    --global \
    --request-path=/health \
    --port=80 \
    --check-interval=30s \
    --timeout=10s

gcloud compute health-checks create http backend-health-check \
    --global \
    --request-path=/health \
    --port=8080 \
    --check-interval=30s \
    --timeout=10s

# Create backend service for frontend
gcloud compute backend-services create frontend-backend-service \
    --global \
    --protocol=HTTP \
    --health-checks=frontend-health-check \
    --session-affinity=CLIENT_IP

# Add instance group to backend service
gcloud compute backend-services add-backend frontend-backend-service \
    --global \
    --instance-group=web-server-group \
    --instance-group-region=us-central1

# Create backend service for backend (internal)
gcloud compute backend-services create backend-backend-service \
    --region=us-central1 \
    --protocol=HTTP \
    --health-checks=backend-health-check \
    --load-balancing-scheme=INTERNAL

# Add instance group to internal backend service
gcloud compute backend-services add-backend backend-backend-service \
    --region=us-central1 \
    --instance-group=app-server-group \
    --instance-group-region=us-central1

# Create URL map
gcloud compute url-maps create frontend-url-map \
    --default-service=frontend-backend-service

# Create HTTP proxy
gcloud compute target-http-proxies create frontend-proxy \
    --url-map=frontend-url-map

# Create forwarding rule
gcloud compute forwarding-rules create frontend-forwarding-rule \
    --global \
    --target-http-proxy=frontend-proxy \
    --address-region=us-central1 \
    --ports=80

# For HTTPS (create SSL certificate first)
gcloud compute ssl-certificates create frontend-ssl-cert \
    --certificate=path/to/cert.pem \
    --private-key=path/to/key.pem

gcloud compute target-https-proxies create frontend-https-proxy \
    --url-map=frontend-url-map \
    --ssl-certificates=frontend-ssl-cert

gcloud compute forwarding-rules create frontend-https-forwarding-rule \
    --global \
    --target-https-proxy=frontend-https-proxy \
    --address-region=us-central1 \
    --ports=443
```

# Monitoring and Maintenance

## Cloud Logging and Cloud Monitoring Setup

### 1. Metrics Configuration
```bash
# View available metrics
gcloud monitoring metrics-descriptors list

# Create custom metric for memory usage
cat << 'EOF' > /opt/gcp/scripts/memory-metrics.sh
#!/bin/bash
MEMORY_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
INSTANCE_ID=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/id)

gcloud monitoring time-series create \
    --metric-type=custom.googleapis.com/memory_usage \
    --resource=gce_instance,instance_id=$INSTANCE_ID \
    --value=$MEMORY_USAGE
EOF

chmod +x /opt/gcp/scripts/memory-metrics.sh

# Add to crontab
echo "* * * * * /opt/gcp/scripts/memory-metrics.sh" | crontab -
```

### 2. Cloud Logging Configuration
```bash
# Create log router sink to save logs
gcloud logging sinks create java-app-sink \
    logging.googleapis.com/projects/PROJECT_ID/logs/java-app \
    --log-filter='resource.type="gce_instance" AND jsonPayload.app="java-app"'

# View logs
gcloud logging read "resource.type=gce_instance" --limit=50 --format=json

# Create log-based metrics
gcloud logging metrics create error_count \
    --description="Count of ERROR level logs" \
    --log-filter='severity="ERROR"'
```

### 3. Cloud Monitoring Alerts
```bash
# Create notification channel
gcloud alpha monitoring channels create \
    --display-name="Email Notification" \
    --type=email \
    --channel-labels=email_address=admin@example.com

# Create alert policy for high CPU
gcloud alpha monitoring policies create \
    --notification-channels=CHANNEL_ID \
    --display-name="High CPU Usage Alert" \
    --condition-display-name="CPU > 80%" \
    --condition-threshold-value=0.8 \
    --condition-threshold-duration=300s
```

### 4. Dashboards
```bash
# Create monitoring dashboard
gcloud monitoring dashboards create --config-from-file=dashboard.json
```

# Security Best Practices

## 1. Network Security
- Implement VPC Service Controls
- Use Cloud Armor for DDoS protection
- Enable VPC Flow Logs for traffic analysis
- Implement private Google access for private subnets
- Use Cloud VPN or Interconnect for secure connectivity

## 2. Application Security
- Regular security patches
- Implement Cloud Armor
- Use Secret Manager for sensitive data
- Enable Binary Authorization
- Implement container image scanning

## 3. Data Security
- Enable encryption at rest (default)
- Use SSL/TLS for data in transit
- Enable Cloud SQL Proxy for secure database access
- Implement backup and disaster recovery strategies
- Regular security audits using Cloud Security Scanner

## 4. Identity and Access Management
- Use service accounts with minimal permissions
- Enable Workload Identity
- Implement IAM policies based on least privilege
- Use Cloud Audit Logs to track all activities
- Regularly review and rotate credentials

# Troubleshooting Guide

## Common Issues and Solutions

### 1. Connection Issues
```bash
# Test connectivity to Cloud SQL
gcloud sql connect prod-mysql --user=root

# Verify firewall rules
gcloud compute firewall-rules list --filter=network:primary-vpc

# Check VPC peering status
gcloud compute networks peerings list

# Test internal load balancer connectivity
gcloud compute ssh INSTANCE_NAME --zone=ZONE -- \
    curl -v http://INTERNAL_LB_IP:8080
```

### 2. Performance Issues
```bash
# Check CPU and memory usage in Cloud Monitoring
gcloud monitoring time-series list \
    --filter='metric.type="compute.googleapis.com/instance/cpu/utilization"'

# Check Cloud SQL performance metrics
gcloud sql instances describe prod-mysql

# Monitor instance group metrics
gcloud compute instance-groups managed describe app-server-group \
    --region=us-central1

# View recent logs for errors
gcloud logging read --limit=50 --format=json resource.type=gce_instance
```

### 3. Load Balancer Issues
```bash
# Check backend service health
gcloud compute backend-services get-health frontend-backend-service \
    --global

# Verify forwarding rules
gcloud compute forwarding-rules list

# Check URL map configuration
gcloud compute url-maps describe frontend-url-map
```

### 4. Auto Scaling Issues
```bash
# Check auto scaling policies
gcloud compute instance-groups managed describe web-server-group \
    --region=us-central1

# View auto scaling operations
gcloud compute operations list --filter='targetLink:web-server-group'

# Manually adjust instance count
gcloud compute instance-groups managed set-autoscaling web-server-group \
    --region=us-central1 \
    --min-num-replicas=3
```

### 5. Database Connection Issues
```bash
# Test Cloud SQL Proxy connection
cloud_sql_proxy -instances=PROJECT_ID:us-central1:prod-mysql=tcp:3306

# Check Cloud SQL logs
gcloud sql operations list --instance=prod-mysql

# Verify user permissions
gcloud sql users describe appuser --instance=prod-mysql
```

# Contributing

## How to Contribute

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Development Setup

```bash
# Clone repository
git clone https://github.com/yourusername/your-repo.git

# Install dependencies
mvn install

# Run tests
mvn test

# Build project
mvn clean package
```

---

## 🛠️ Author & Community

This project is maintained by **[Harshhaa](https://github.com/NotHarshhaa)** 💡.
Your feedback and contributions are welcome!

📧 **Connect with me:**
- **GitHub**: [@NotHarshhaa](https://github.com/NotHarshhaa)
- **Blog**: [ProDevOpsGuy](https://blog.prodevopsguytech.com)
- **Telegram Community**: [Join Here](https://t.me/prodevopsguy)
- **LinkedIn**: [Harshhaa Vardhan Reddy](https://www.linkedin.com/in/harshhaa-vardhan-reddy/)

---

## ⭐ Support the Project

If you found this project helpful, please consider:
- **Starring** ⭐ the repository
- **Sharing** it with your network
- **Contributing** to its improvement

### 📢 Stay Connected

![Follow Me](https://imgur.com/2j7GSPs.png)

> [!Important]
> This documentation is continuously evolving. For the latest updates, please check the repository regularly.
