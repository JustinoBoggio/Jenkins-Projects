#!/bin/bash
# Description: Initialization script for Jenkins Agent node with Docker support
# Target OS: Ubuntu 22.04 LTS

# 1. System Update
echo "Updating system packages..."
apt-get update && apt-get upgrade -y

# 2. Install Java (Agent Requirement)
# The agent needs the same Java version major as the master to communicate
echo "Installing Java 17..."
apt-get install -y openjdk-17-jre git

# 3. Install Docker Engine
echo "Installing Docker..."
apt-get install -y docker.io

# 4. Configure Permissions
# Add default 'ubuntu' user to docker group to run commands without sudo
echo "Configuring user permissions..."
usermod -aG docker ubuntu

# Create dedicated directory for Jenkins workspace
mkdir -p /var/lib/jenkins
chown -R ubuntu:ubuntu /var/lib/jenkins

# 5. Start Docker
systemctl enable docker
systemctl start docker

echo "Jenkins Agent setup complete."