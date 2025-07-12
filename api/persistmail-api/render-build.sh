#!/bin/bash
# Render build script - runs automatically on deployment

set -e

echo "🚀 Starting Render deployment build..."

# Install dependencies
pip install -r requirements.txt

# Run database migrations
python scripts/migrate.py

echo "✅ Render build completed successfully"
