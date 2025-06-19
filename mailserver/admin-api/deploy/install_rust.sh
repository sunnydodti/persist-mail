#!/bin/bash
set -e

echo "Installing dependencies using yum..."
sudo yum clean all
sudo yum update -y

echo "Installing build dependencies..."
sudo yum groupinstall -y "Development Tools"
sudo yum install -y --allowerasing \
    gcc \
    gcc-c++ \
    make \
    openssl-devel \
    pkg-config \
    git

echo "Installing Rust..."
# Download and run rustup installer
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Add cargo to PATH for this session
source "$HOME/.cargo/env"

# Check Rust installation
rustc --version || {
    echo "Error: Rust installation failed"
    exit 1
}

# Verify cargo is working
cargo --version || {
    echo "Error: Cargo is not working"
    exit 1
}

echo "Rust installation successful!"
