#!/bin/bash
# Render start script

set -e

echo "🚀 Starting PersistMail API..."

# Run database migration
python scripts/migrate.py

# Start the application
uvicorn main:app --host 0.0.0.0 --port $PORT
