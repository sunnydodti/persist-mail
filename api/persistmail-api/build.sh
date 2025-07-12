#!/bin/bash
# Render build script

set -e

echo "🚀 Starting Render build..."

# Install dependencies
pip install -r requirements.txt

echo "✅ Build completed successfully"
