#!/bin/bash
set -e

# Update system packages
echo "Updating system packages..."
sudo yum update -y

# Install Rust if not installed
if ! command -v rustc &> /dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
fi

# Source cargo environment
source "$HOME/.cargo/env"

# Navigate to app directory
cd "$HOME/mail-admin-api"

# Build the Rust project
echo "Building Rust project..."
cargo build --release

# Verify binary exists and is executable
if [ ! -f "./target/release/mail-admin-api" ]; then
    echo "Error: Binary not found after build"
    exit 1
fi

chmod +x ./target/release/mail-admin-api

# Test binary
./target/release/mail-admin-api --version || {
    echo "Error: Binary verification failed"
    exit 1
}

# Check if systemd service exists
if [ -f /etc/systemd/system/mail-admin-api.service ]; then
    echo "Starting mail-admin-api service..."
    sudo systemctl daemon-reload
    sudo systemctl restart mail-admin-api
    sleep 2  # Give service time to start
    sudo systemctl status mail-admin-api
else
    echo "Running mail-admin-api directly..."
    # Run the release binary
    ./target/release/mail-admin-api
fi
