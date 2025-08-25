# GitHub Actions CI/CD Setup Guide

This guide explains how to set up automated deployment of your Vite + React application to a VPS using GitHub Actions, Docker, and Nginx with SSL.

## Architecture Overview

- **GitHub Actions**: Builds and pushes Docker images to GitHub Container Registry
- **Docker**: Containerizes the application for consistent deployments
- **Nginx**: Serves the React app with SSL termination
- **Certbot**: Manages SSL certificates (Let's Encrypt)

## Setup Instructions

### 1. GitHub Repository Secrets

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

```
VPS_HOST=your-vps-ip-address
VPS_USERNAME=your-ssh-username
VPS_SSH_KEY=your-private-ssh-key-content
```

### 2. VPS Prerequisites

On your VPS, ensure you have Docker and Docker Compose installed:

```bash
# Method 1: Install Docker with Compose plugin (Recommended)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose plugin
sudo apt-get update
sudo apt-get install docker-compose-plugin

# Add your user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Method 2: If the above doesn't work, install standalone Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker compose version
```

**Troubleshooting Docker Compose:**

If you get "docker: 'compose' is not a docker command", try these solutions:

```bash
# Option 1: Use docker-compose (with hyphen) instead
docker-compose --version

# Option 2: Install the compose plugin
sudo apt-get update && sudo apt-get install docker-compose-plugin

# Option 3: Use standalone docker-compose
which docker-compose
/usr/local/bin/docker-compose --version
```

### 3. VPS Directory Structure

Create the project directory:

```bash
sudo mkdir -p /opt/pedru-dev
sudo chown $USER:$USER /opt/pedru-dev
```

### 4. Domain Configuration

Ensure your domain points to your VPS:

```bash
# Check DNS resolution
nslookup pedru.dev.br
nslookup www.pedru.dev.br
```

### 5. SSL Certificate Setup

The application will automatically:
- Generate self-signed certificates for development
- Attempt to get Let's Encrypt certificates in production
- Set up automatic renewal

## Deployment Process

### Automatic Deployment

1. Push to `main` branch triggers the workflow
2. GitHub Actions builds the Docker image
3. Image is pushed to GitHub Container Registry
4. VPS pulls the new image and restarts containers

### Manual Deployment

You can also deploy manually on your VPS:

```bash
cd /opt/pedru-dev
./deploy.sh
```

## Monitoring and Maintenance

### Check Application Status

```bash
# Check running containers
docker ps

# View application logs
docker compose logs -f

# Check nginx configuration
docker exec pedru-dev nginx -t
```

### SSL Certificate Renewal

Certificates auto-renew, but you can manually renew:

```bash
# Run certbot renewal
docker compose --profile renewal run --rm certbot

# Restart nginx to load new certificates
docker compose restart nginx-react
```

### Troubleshooting

1. **Container won't start**:
   ```bash
   docker compose logs nginx-react
   # or
   docker-compose logs nginx-react
   ```

2. **"docker: 'compose' is not a docker command" error**:
   ```bash
   # Try with hyphen instead
   docker-compose --version
   
   # Or install the compose plugin
   sudo apt-get install docker-compose-plugin
   
   # Or check if standalone docker-compose is installed
   which docker-compose
   ```

3. **SSL issues**:
   ```bash
   docker exec pedru-dev ls -la /etc/letsencrypt/live/pedru.dev.br/
   ```

4. **Build failures**:
   Check GitHub Actions logs in your repository

5. **Permission denied errors**:
   ```bash
   # Make sure your user is in the docker group
   sudo usermod -aG docker $USER
   newgrp docker
   
   # Or run with sudo
   sudo docker compose up -d
   ```

## Security Considerations

- SSH keys are stored as GitHub secrets
- Docker images are stored in private GitHub Container Registry
- SSL certificates are automatically managed
- Regular security updates via Alpine Linux base image

## Performance Optimization

- Multi-stage Docker build reduces image size
- nginx serves static files efficiently
- Automatic old image cleanup prevents disk space issues

## Rollback Process

To rollback to a previous version:

```bash
# List available images
docker images ghcr.io/lpedrul/pedru-dev

# Use a specific tag
docker compose down
docker tag ghcr.io/lpedrul/pedru-dev:previous-tag ghcr.io/lpedrul/pedru-dev:latest
docker compose up -d
```
