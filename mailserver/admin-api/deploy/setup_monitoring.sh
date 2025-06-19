#!/bin/bash
set -e

# Install monitoring tools
sudo yum update -y
sudo yum install -y \
    prometheus-node_exporter \
    collectd \
    sysstat

# Create log directory
sudo mkdir -p /var/log/mail-admin-api
sudo chown ec2-user:ec2-user /var/log/mail-admin-api

# Setup basic monitoring for the service
sudo mkdir -p /etc/collectd/collectd.conf.d
sudo tee /etc/collectd/collectd.conf.d/mail-admin-api.conf << EOF
LoadPlugin processes
<Plugin processes>
    ProcessMatch "mail-admin-api" "mail-admin-api"
</Plugin>

LoadPlugin cpu
LoadPlugin memory
LoadPlugin load
LoadPlugin disk
LoadPlugin interface

LoadPlugin syslog
<Plugin syslog>
    LogLevel info
</Plugin>
EOF

# Start collectd if not running
sudo systemctl enable collectd
sudo systemctl restart collectd

# Setup log monitoring
sudo tee /etc/rsyslog.d/mail-admin-api.conf << EOF
if \$programname == 'mail-admin-api' then /var/log/mail-admin-api/application.log
& stop
EOF

# Restart rsyslog
sudo systemctl restart rsyslog

echo "Monitoring setup complete. Logs available at /var/log/mail-admin-api/application.log"
