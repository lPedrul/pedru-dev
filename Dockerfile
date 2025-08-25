# Multi-stage build for production
FROM node:18-alpine AS build

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM nginx:alpine AS production

# Install certbot and openssl for SSL
RUN apk add --no-cache certbot certbot-nginx openssl

# Copy built application
COPY --from=build /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY nginx/default.conf /etc/nginx/nginx.conf

# Create directories for Let's Encrypt and certbot webroot
RUN mkdir -p /etc/letsencrypt/live/pedru.dev.br /var/www/certbot

# Generate self-signed certificates as fallback
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/letsencrypt/live/pedru.dev.br/privkey.pem \
    -out /etc/letsencrypt/live/pedru.dev.br/fullchain.pem \
    -subj "/C=BR/ST=State/L=City/O=Organization/CN=pedru.dev.br"

# Download SSL configuration files
RUN wget -O /etc/letsencrypt/options-ssl-nginx.conf \
    https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf
RUN wget -O /etc/letsencrypt/ssl-dhparams.pem \
    https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem

# Copy entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80 443

CMD ["/docker-entrypoint.sh"]
