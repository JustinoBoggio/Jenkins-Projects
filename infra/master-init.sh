#!/bin/bash
# Description: Initialization script for Jenkins Master node on Ubuntu 22.04
# Author: Justino Boggio & Mauricio Agustin Batista

# 1. System Update
echo "Updating system packages..."
apt-get update && apt-get upgrade -y

# 2. Install Dependencies
# OpenJDK 17 is required for recent Jenkins versions
echo "Installing Java 17 and Git..."
apt-get install -y openjdk-17-jre git curl unzip

# 3. Install Jenkins (LTS Version)
echo "Adding Jenkins repository and key..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "Installing Jenkins..."
apt-get update
apt-get install -y jenkins

# 4. Start Services
echo "Starting Jenkins service..."
systemctl enable jenkins
systemctl start jenkins

# 5. Firewall Configuration (Optional if handled by Azure NSG, but good practice)
# ufw allow 8080
# ufw allow OpenSSH
# ufw enable

echo "Jenkins Master setup complete."