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

apt-get -y update
wget "https://storage.googleapis.com/releases.grr-response.com/grr-server_3.2.1-1_amd64.deb"
env DEBIAN_FRONTEND=noninteractive apt install -y ./grr-server_3.2.1-1_amd64.deb
service grr-server stop

apt-get -y install nginx
cd /etc/nginx
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=${grr_server_host}" -keyout /etc/nginx/cert.key -out /etc/nginx/cert.crt

cat <<"EOF" > /etc/nginx/sites-enabled/default
server {
    listen 80;
    return 301 https://$$host$$request_uri;
}

server {
    listen 443;
    server_name ${grr_server_host};

    ssl_certificate           /etc/nginx/cert.crt;
    ssl_certificate_key       /etc/nginx/cert.key;

    ssl on;
    ssl_session_cache  builtin:1000  shared:SSL:10m;
    ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
    ssl_prefer_server_ciphers on;

    access_log            /var/log/nginx/grr.access.log;

    location / {

      proxy_set_header        Host $$host;
      proxy_set_header        X-Real-IP $$remote_addr;
      proxy_set_header        X-Forwarded-For $$proxy_add_x_forwarded_for;
      proxy_set_header        X-Forwarded-Proto $$scheme;

      # Fix the 'It appears that your reverse proxy set up is broken' error.
      proxy_pass          http://localhost:8000;
      proxy_read_timeout  180;

      proxy_redirect      http://localhost:8000 https://${grr_server_host};
    }
}
EOF
sudo service nginx restart


cat << EOF > /etc/grr/server.local.yaml
Datastore.implementation: MySQLAdvancedDataStore
Mysql.host: ${grr_db_host}
Mysql.port: 3306
Mysql.database_name: ${grr_db_name}
Mysql.database_username: ${grr_db_user}
Mysql.database_password: ${grr_db_password}

Client.server_urls: http://${grr_server_host}:8080/
Frontend.bind_port: 8080
AdminUI.url: https://${grr_server_host}:8000
AdminUI.port: 8000
Logging.domain: localhost
Monitoring.alert_email: grr-monitoring@localhost
Monitoring.emergency_access_email: grr-emergency@localhost
Rekall.enabled: 'False'
Server.initialized: 'True'

Client.foreman_check_frequency: 30
Client.poll_max: 5
EOF

grr_config_updater generate_keys
grr_config_updater repack_clients

grr_config_updater add_user --password ${grr_admin_password} admin

service grr-server start

gsutil cp /usr/share/grr-server/executables/installers/*.{exe,deb,rpm,pkg} ${grr_client_installers_bucket}

# --- END MAIN ---

# --- AFTER MAIN (DO NOT EDIT)

date > "$${STARTUP_FINISHED_FILE}"
echo "Startup script finished successfully"

# --- END AFTER MAIN ---
