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

# Start docker if not running
sudo systemctl start docker
sudo systemctl enable docker

# Build the Rust project
echo "Building Rust project..."
source "$HOME/.cargo/env"
cargo clean
cargo build --release
check_error "Failed to build Rust project"

echo "Setting up service..."
# Copy service file if it exists
if [ -f mail-admin-api.service ]; then
    sudo cp mail-admin-api.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable mail-admin-api
    sudo systemctl restart mail-admin-api
fi

echo "Opening firewall port..."
if command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-port=5000/tcp
    sudo firewall-cmd --reload
fi

echo "Deployment complete!"
