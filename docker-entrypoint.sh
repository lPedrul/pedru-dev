#!/bin/bash

# Check if running in production and if real certificates should be obtained
if [ "$CERTBOT_EMAIL" ] && [ "$PRODUCTION" = "true" ]; then
    echo "Attempting to obtain Let's Encrypt certificates..."
    
    # Start nginx in background for the challenge
    nginx &
    
    # Wait for nginx to start
    sleep 5
    
    # Try to obtain certificates
    certbot certonly \
        --webroot \
        --webroot-path=/usr/share/nginx/html \
        --email $CERTBOT_EMAIL \
        --agree-tos \
        --no-eff-email \
        --domains pedru.dev.br,www.pedru.dev.br
    
    if [ $? -eq 0 ]; then
        echo "Certificates obtained successfully!"
        # Stop the background nginx
        pkill nginx
        
        # Setup automatic renewal
        echo "0 12 * * * /usr/bin/certbot renew --quiet" | crontab -
        service cron start
    else
        echo "Failed to obtain certificates, using self-signed certificates"
    fi
else
    echo "Using self-signed certificates (development mode)"
fi

# Start nginx in foreground
exec nginx -g "daemon off;"
