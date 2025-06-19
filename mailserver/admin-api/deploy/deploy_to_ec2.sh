#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Check required commands
commands=("aws" "scp" "ssh")
for cmd in "${commands[@]}"; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}Error: $cmd is required but not installed.${NC}"
        exit 1
    fi
done

# Configuration
EC2_USER="ec2-user"  # or "ec2-user" for Amazon Linux
EC2_HOST="ec2-user@ec2-13-126-52-84.ap-south-1.compute.amazonaws.com"        # Your EC2 instance hostname or IP
PEM_FILE="../../../credentials/mail-pair.pem"        # Path to your .pem file

# Parse command line arguments
while getopts "h:k:u:" opt; do
    case ${opt} in
        h)
            EC2_HOST=$OPTARG
            ;;
        k)
            PEM_FILE=$OPTARG
            ;;
        u)
            EC2_USER=$OPTARG
            ;;
        \?)
            echo "Usage: $0 -h hostname -k pemfile [-u username]"
            exit 1
            ;;
    esac
done

if [[ -z "$EC2_HOST" || -z "$PEM_FILE" ]]; then
    echo "Usage: $0 -h hostname -k pemfile [-u username]"
    exit 1
fi

# Function to run remote commands
remote_exec() {
    ssh -i "$PEM_FILE" -o StrictHostKeyChecking=no "${EC2_USER}@${EC2_HOST}" "$1"
}

echo -e "${GREEN}Preparing for deployment...${NC}"

# Create remote directory
echo "Creating remote directory..."
remote_exec "mkdir -p ~/mail-admin-api"

# Copy project files
echo "Copying project files..."
scp -i "$PEM_FILE" -r ../Cargo.toml ../Cargo.lock ../src "${EC2_USER}@${EC2_HOST}:~/mail-admin-api/"
scp -i "$PEM_FILE" ../mail-admin-api.service "${EC2_USER}@${EC2_HOST}:~/mail-admin-api/"
scp -i "$PEM_FILE" deploy.sh install_rust.sh start.sh "${EC2_USER}@${EC2_HOST}:~/mail-admin-api/"

# Install build dependencies and Rust
echo "Installing build dependencies..."
remote_exec "cd ~/mail-admin-api && sudo yum clean all && \
    sudo yum groupinstall -y 'Development Tools' && \
    sudo yum install -y gcc gcc-c++ make cmake openssl-devel pkg-config git"

# Install Rust if not already installed
echo "Installing Rust..."
remote_exec "cd ~/mail-admin-api && bash install_rust.sh"

# Source cargo environment and build
echo "Building and deploying..."
remote_exec "source \$HOME/.cargo/env && cd ~/mail-admin-api && bash deploy.sh"

# Verify the service is running and port is accessible
echo "Verifying service status..."
remote_exec "sudo systemctl status mail-admin-api || true"
remote_exec "sudo netstat -tlpn | grep 5000 || true"

# Configure firewall if needed
echo "Configuring firewall..."
remote_exec "sudo systemctl status firewalld >/dev/null 2>&1 && sudo firewall-cmd --permanent --add-port=5000/tcp && sudo firewall-cmd --reload || true"

# Check AWS security group
echo "Note: Ensure port 5000 is open in the EC2 security group"
echo "You can open it with: aws ec2 authorize-security-group-ingress --group-id YOUR_SECURITY_GROUP_ID --protocol tcp --port 5000 --cidr 0.0.0.0/0"

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo "Testing service accessibility..."
remote_exec "curl -v localhost:5000/health || true"
echo ""
echo "You can test the API using:"
echo "curl -X POST -H \"X-API-Key: <your-api-key>\" http://${EC2_HOST}:5000/mailbox/testuser"
