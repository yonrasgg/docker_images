# Use the Puppet Server image as the base
FROM puppet/puppetserver:latest

# Set necessary environment variables
ENV PUPPETDB_SERVER_URLS="https://puppetdb:8281"

# Copy a customized version of the puppetdb.conf file
COPY ./puppetdb.conf /etc/puppetlabs/puppet/puppetdb.conf

# Set permissions for the necessary files
RUN mkdir -p /etc/puppetlabs/puppet/ssl/certs && \
    mkdir -p /etc/puppetlabs/puppetserver/conf.d && \
    chown -R puppet:puppet /etc/puppetlabs/puppet

# Generate SSL certificates when building the image
RUN puppetserver ca setup

# Copy the initialization script
COPY init_puppetserver.sh /usr/local/bin/init_puppetserver.sh
RUN chmod +x /usr/local/bin/init_puppetserver.sh

# Replace the ENTRYPOINT with the script
ENTRYPOINT ["/usr/local/bin/init_puppetserver.sh"]
CMD ["foreground"]