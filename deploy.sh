#!/bin/bash

# Deploy script for VPS
set -e

PROJECT_DIR="/opt/pedru-dev"
COMPOSE_FILE="docker-compose.yml"
IMAGE_NAME="ghcr.io/lpedrul/pedru-dev:latest"

echo "🚀 Starting deployment..."

# Determine which compose command to use
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo "❌ Neither docker compose nor docker-compose found!"
    echo "Please install Docker Compose. See DEPLOYMENT.md for instructions."
    exit 1
fi

echo "✅ Using compose command: $COMPOSE_CMD"

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
$COMPOSE_CMD down || true

# Remove old images (keep last 2)
echo "🧹 Cleaning up old images..."
docker images $IMAGE_NAME --format "table {{.Repository}}:{{.Tag}}\t{{.ID}}" | tail -n +3 | awk '{print $2}' | tail -n +3 | xargs -r docker rmi || true

# Start new containers
echo "🔄 Starting new containers..."
$COMPOSE_CMD up -d

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
    $COMPOSE_CMD logs --tail=20
    exit 1
fi

echo "🎉 Deployment completed successfully!"
