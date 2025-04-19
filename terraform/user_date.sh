#!/bin/bash

set -e

# Install dependencies
apt update
apt install -y docker.io curl git unzip

# Add docker permission
usermod -aG docker ubuntu

# Install kubectl
curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
chmod +x kubectl && mv kubectl /usr/local/bin/

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube-linux-amd64 && mv minikube-linux-amd64 /usr/local/bin/minikube

# Start Minikube with 6GB RAM
minikube start --driver=docker --memory=6144 --cpus=2

# Clone repo
git clone https://github.com/CTSE-Assignment-Y4-SE/infrastructure.git /home/ubuntu/infrastructure

# Run deployment
cd /home/ubuntu/infrastructure
chmod +x deploy.sh
./deploy.sh
