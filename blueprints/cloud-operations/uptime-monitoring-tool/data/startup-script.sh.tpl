#! /bin/bash

# Define shared variables
UPTIME_MON_SOURCE_NAME=${uptime_mon_source_name}
UPTIME_MON_CONFIG_NAME=${uptime_mon_config_name}
BUCKET_NAME=${bucket_name}
CONFIG_SYNC_SOURCE_NAME=${config_sync_source_name}
CONFIG_SYNC_CONFIG_NAME=${config_sync_config_name}

# Install or update needed software
apt-get update
apt-get install -yq git supervisor python python3-pip python3-distutils unzip
pip install --upgrade pip virtualenv

export HOME=/root
mkdir -p /opt/app/source
mkdir -p /opt/config_sync/source

# Fetch Networking Monitoring agent and config sync source code and config
gsutil cp gs://$BUCKET_NAME/$UPTIME_MON_SOURCE_NAME /tmp
gsutil cp gs://$BUCKET_NAME/$UPTIME_MON_CONFIG_NAME /tmp
gsutil cp gs://$BUCKET_NAME/$CONFIG_SYNC_SOURCE_NAME /tmp
gsutil cp gs://$BUCKET_NAME/$CONFIG_SYNC_CONFIG_NAME /tmp

# Stop any running instance of the script before updating the source code
supervisorctl stop all

# Move source code in the destination folder overriding existing source code
# for both net-mon-agent and config-sync scripts
rm -rf /opt/app/source/*
rm -rf /opt/config_sync/source/*
unzip /tmp/$UPTIME_MON_SOURCE_NAME -d /opt/app/source
unzip /tmp/$CONFIG_SYNC_SOURCE_NAME -d /opt/config_sync/source

# Put supervisor configuration in proper place
cp -f /tmp/$UPTIME_MON_CONFIG_NAME /etc/supervisor/conf.d/$UPTIME_MON_CONFIG_NAME
cp -f /tmp/$CONFIG_SYNC_CONFIG_NAME /etc/supervisor/conf.d/$CONFIG_SYNC_CONFIG_NAME

if id "net-mon-agent" >/dev/null 2>&1; then
  echo 'User net-mon-agent found, skipping setup...'
else
  # Account to own server process
  useradd -m -d /home/net-mon-agent net-mon-agent

  # Set ownership to newly created account
  chown -R net-mon-agent:net-mon-agent /opt/app
fi

# Check if python virtualenv already exists, otherwise initialize it
if [ ! -d "/opt/app/env" ]; then
  # Python environment setup
  virtualenv -p python3 /opt/app/env
  /opt/app/env/bin/pip install -r /opt/app/source/requirements.txt
fi

if [ ! -d "/opt/config_sync/env" ]; then
  # Python environment setup
  virtualenv -p python3 /opt/config_sync/env
  /opt/config_sync/env/bin/pip install -r /opt/config_sync/source/requirements.txt
fi

if id "net-mon-config-sync" >/dev/null 2>&1; then
  echo 'User net-mon-config-sync found, skipping setup...'
else
  # Create user net-mon-config-sync
  useradd -m -d /home/net-mon-config-sync net-mon-config-sync

  # Set ownership to newly created account
  chown -R net-mon-config-sync:net-mon-config-sync /opt/config_sync

  # Change group ownership of squid config folder and file
  chgrp net-mon-config-sync /etc/supervisor/conf.d/
  chgrp net-mon-config-sync /etc/supervisor/conf.d/"$UPTIME_MON_CONFIG_NAME"
  chmod g+rwx /etc/supervisor/conf.d/
  chmod g+rwx /etc/supervisor/conf.d/"$UPTIME_MON_CONFIG_NAME"
fi

# Update supervisorctl permissions
sed -i 's/0700/0766/g' /etc/supervisor/supervisord.conf
service supervisor restart

# Start service via supervisorctl
supervisorctl reread
supervisorctl update
