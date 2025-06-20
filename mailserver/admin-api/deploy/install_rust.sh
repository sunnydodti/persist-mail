#!/bin/bash
set -e

# Check if Rust is already installed
if command -v rustc &> /dev/null && command -v cargo &> /dev/null; then
    echo "Rust and Cargo are already installed"
    rustc --version
    cargo --version
    exit 0
fi

echo "Installing dependencies using yum..."
# Only update package list, don't upgrade everything
sudo yum clean all >/dev/null 2>&1
sudo yum check-update >/dev/null 2>&1 || true

echo "Installing build dependencies..."
# Only install missing packages, quietly
for pkg in gcc gcc-c++ make openssl-devel pkg-config git; do
    if ! rpm -q $pkg &> /dev/null; then
        PKGS_TO_INSTALL="$PKGS_TO_INSTALL $pkg"
    fi
done

if [ ! -z "$PKGS_TO_INSTALL" ]; then
    sudo yum install -y -q --allowerasing $PKGS_TO_INSTALL
fi

echo "Installing Rust..."
# Download and run rustup installer (suppress progress output)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y >/dev/null 2>&1

# Add cargo to PATH for this session
source "$HOME/.cargo/env" || {
    echo "Error: Failed to source cargo environment"
    exit 1
}

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
