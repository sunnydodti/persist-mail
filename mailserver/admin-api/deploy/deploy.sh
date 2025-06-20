#!/bin/bash
set -e

echo "Starting deployment..."

# Initialize variables
APP_DIR="$HOME/mail-admin-api"
LOG_DIR="$HOME/mail-admin-api/logs"

# Function to check command success
check_error() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    fi
}

# Create necessary directories
mkdir -p "$LOG_DIR"

# Install dependencies and build
cd "$APP_DIR"

echo "Installing dependencies..."
sudo yum update -y
sudo yum groupinstall -y "Development Tools"
sudo yum install -y \
    gcc \
    gcc-c++ \
    make \
    cmake \
    openssl-devel \
    pkg-config \
    git \
    docker
check_error "Failed to install dependencies"

# Configure Docker
echo "Configuring Docker..."
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group if not already added
if ! groups | grep -q docker; then
    sudo usermod -aG docker $USER
    echo "Added $USER to docker group. You may need to log out and back in for this to take effect."
    # Force group update without logout
    newgrp docker
fi

# Verify Docker is working
echo "Verifying Docker setup..."
docker ps >/dev/null 2>&1 || {
    echo "Error: Cannot connect to Docker. Please check Docker permissions."
    echo "You may need to log out and log back in for group changes to take effect."
    exit 1
}

# Verify mailserver container
echo "Checking mailserver container..."
if ! docker ps --format '{{.Names}}' | grep -q '^mailserver$'; then
    echo "Warning: mailserver container not found or not running"
    echo "Checking if container exists..."
    if docker ps -a --format '{{.Names}}' | grep -q '^mailserver$'; then
        echo "Found stopped mailserver container, starting it..."
        docker start mailserver
    else
        echo "Error: mailserver container not found. Mail operations will fail."
        echo "Please ensure the mailserver container is properly set up with name 'mailserver'"
    fi
fi

# Verify mailserver setup.sh script
echo "Checking mailserver setup script..."
if ! docker exec mailserver test -f /usr/local/bin/setup.sh; then
    echo "Error: setup.sh not found in mailserver container"
    echo "Please ensure the mailserver container is properly configured"
    exit 1
fi

# Verify setup.sh permissions
echo "Checking setup script permissions..."
docker exec mailserver ls -l /usr/local/bin/setup.sh
docker exec mailserver chmod +x /usr/local/bin/setup.sh

# Build the Rust project
echo "Building Rust project..."
source "$HOME/.cargo/env"
cargo clean
cargo build --release
check_error "Failed to build Rust project"

# Verify the build
echo "Verifying build..."
if [ ! -f "./target/release/mail-admin-api" ]; then
    echo "Error: Build verification failed - binary not found"
    exit 1
fi

# Make binary executable
chmod +x "./target/release/mail-admin-api"

# Set up service user permissions
echo "Configuring service permissions..."
sudo usermod -aG docker ec2-user
sudo setcap cap_net_bind_service=+ep ./target/release/mail-admin-api

# Test Docker access
echo "Testing Docker access..."
if ! docker exec mailserver /usr/local/bin/setup.sh help >/dev/null 2>&1; then
    echo "Error: Cannot execute setup.sh in mailserver container"
    echo "Please check Docker permissions and container configuration"
    exit 1
fi

# Copy service file
echo "Setting up service..."
sudo cp ./mail-admin-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable mail-admin-api
sudo systemctl restart mail-admin-api

# Configure firewall
echo "Configuring firewall..."
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload

echo "Verifying service can access Docker..."
sleep 2
curl -s -X POST -H "X-API-Key: test-key-123" http://localhost:5000/mailbox/test-verify
test_exit=$?
if [ $test_exit -ne 0 ]; then
    echo "Warning: Service may not have proper Docker access"
    echo "Docker permissions:"
    ls -l /var/run/docker.sock
    groups ec2-user
fi

echo "Deployment complete!"
