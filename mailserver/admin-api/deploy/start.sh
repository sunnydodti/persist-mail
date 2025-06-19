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

# Build the Rust project
echo "Building Rust project..."
cd ~/mail-admin-api
cargo build --release

# Source cargo environment
source "$HOME/.cargo/env"

# Navigate to app directory
cd "$HOME/mail-admin-api"

# Check if systemd service exists
if [ -f /etc/systemd/system/mail-admin-api.service ]; then
    echo "Starting mail-admin-api service..."
    sudo systemctl start mail-admin-api
    sudo systemctl status mail-admin-api
else
    echo "Running mail-admin-api directly..."
    # Run the release binary
    ./target/release/mail-admin-api
fi
