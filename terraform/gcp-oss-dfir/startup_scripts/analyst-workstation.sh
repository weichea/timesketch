#!/bin/bash

# --- BEFORE MAIN (DO NOT EDIT) ---

# Exit on any error
set -e

# Default constants.
readonly BOOT_FINISHED_FILE="/var/lib/cloud/instance/boot-finished"
readonly STARTUP_FINISHED_FILE="/var/lib/cloud/instance/startup-script-finished"

# Redirect stdout and stderr to logfile
exec > /var/log/terraform_provision.log
exec 2>&1

# Exit if the startup script has already been executed successfully
if [[ -f "$${STARTUP_FINISHED_FILE}" ]]; then
  exit 0
fi

# Wait for cloud-init to finish all tasks
until [[ -f "$${BOOT_FINISHED_FILE}" ]]; do
  sleep 1
done

# --- END BEFORE MAIN ---

# --- MAIN ---

# Add Plaso repository
add-apt-repository -y ppa:gift/stable
apt-get update

# Install tools
apt-get install -y python-plaso plaso-tools python-pip xmount sleuthkit libfvde-tools libbde-tools jq ncdu htop binutils upx-ucl screen tmux

# Install and configure dfTimewolf
git clone https://github.com/log2timeline/dftimewolf.git
pip install ./dftimewolf/

cat > /etc/dftimewolf.conf <<EOF
{
  "ts_username": "${timesketch_admin_user}",
  "ts_password": "${timesketch_admin_password}",
  "ts_endpoint": "https://${timesketch_server_host}/",
  "grr_server_url": "https://${grr_server_host}/",
  "grr_username": "${grr_admin_user}",
  "grr_password": "${grr_admin_password}",
  "verify": false
}
EOF

# --- END MAIN ---


# --- AFTER MAIN (DO NOT EDIT)

date > "$${STARTUP_FINISHED_FILE}"
echo "Startup script finished successfully"

# --- END AFTER MAIN ---
