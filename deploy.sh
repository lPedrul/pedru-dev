#!/bin/bash

# Deploy script for VPS
set -e

PROJECT_DIR="/opt/pedru-dev"
COMPOSE_FILE="docker-compose.yml"
IMAGE_NAME="ghcr.io/lpedrul/pedru-dev:latest"

echo "🚀 Starting deployment..."

# Create project directory if it doesn't exist
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Download docker-compose.yml if it doesn't exist
if [ ! -f $COMPOSE_FILE ]; then
    echo "📦 Downloading docker-compose.yml..."
    curl -o $COMPOSE_FILE https://raw.githubusercontent.com/lpedrul/pedru-dev/main/docker-compose.yml
fi

# Pull the latest image
echo "📥 Pulling latest image..."
docker pull $IMAGE_NAME

# Stop and remove old containers
echo "🛑 Stopping old containers..."
docker compose down || true

# Remove old images (keep last 2)
echo "🧹 Cleaning up old images..."
docker images $IMAGE_NAME --format "table {{.Repository}}:{{.Tag}}\t{{.ID}}" | tail -n +3 | awk '{print $2}' | tail -n +3 | xargs -r docker rmi || true

# Start new containers
echo "🔄 Starting new containers..."
docker compose up -d

# Wait for container to be healthy
echo "⏳ Waiting for application to start..."
sleep 10

# Check if the application is running
if curl -f http://localhost > /dev/null 2>&1; then
    echo "✅ Deployment successful!"
    echo "🌐 Application is running at http://$(hostname -I | awk '{print $1}')"
else
    echo "❌ Deployment failed - application is not responding"
    echo "📋 Container logs:"
    docker compose logs --tail=20
    exit 1
fi

echo "🎉 Deployment completed successfully!"
