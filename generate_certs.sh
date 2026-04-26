#!/bin/bash

# Generate SSL certificates for development

echo "Generating SSL certificates..."

# Create certs directory if it doesn't exist
mkdir -p certs

# Generate private key and certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/localhost-key.pem \
  -out certs/localhost.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,DNS:api1,DNS:api2,DNS:api3,IP:127.0.0.1"

# Set proper permissions
chmod 600 certs/localhost-key.pem
chmod 644 certs/localhost.pem

echo "Certificates generated successfully!"
echo "Location: ./certs/"
ls -la certs/
