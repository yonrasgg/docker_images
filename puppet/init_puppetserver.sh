#!/bin/bash

SSL_DIR="/etc/puppetlabs/puppet/ssl"
CERTS_DIR="$SSL_DIR/certs"

# Check if the certificates already exist
if [ ! -d "$CERTS_DIR" ] || [ ! "$(ls -A $CERTS_DIR)" ]; then
    echo "Certificates not found. Generating certificates..."
    puppetserver ca setup

    if [ $? -ne 0 ]; then
        echo "Error generating certificates. Check the configuration." >&2
        exit 1
    fi
else
    echo "Existing certificates. Continuing with startup..."
fi

# Start Puppetserver
exec /opt/puppetlabs/server/apps/puppetserver/bin/puppetserver "$@"
