#!/bin/bash
set -e

# --- Configurable Variables ---
if [[ "$1" == "install" ]]; then
  echo "─────────────── NTFY Installation ───────────────"
  read -p "Enter your domain or public IP (e.g. 203.0.113.45): " PUBLIC_IP
  read -p "Enter topic name to use with ntfy: " NTFY_TOPIC
  read -p "Enter admin username: " NTFY_USER
  read -sp "Enter admin password: " NTFY_PASS
  echo ""
fi
CERT_DIR="/etc/ssl/ntfy"
NGINX_HTPASSWD="/etc/nginx/ntfy.htpasswd"
NTFY_DB="/var/lib/ntfy/user.db"
NTFY_CONFIG="/etc/ntfy/server.yml"
NTFY_CERT="$CERT_DIR/ntfy.crt"
NTFY_KEY="$CERT_DIR/ntfy.key"

# --- OS Detection ---
if [[ "$1" == "install" ]]; then
  echo "[*] Detecting OS..."
  . /etc/os-release || { echo "[!] /etc/os-release missing"; exit 1; }
  DISTRO=$ID
fi

# --- Command Handlers ---
function install_ntfy() {
    echo "[*] Installing dependencies for $DISTRO"
    if [[ "$DISTRO" =~ (ubuntu|debian) ]]; then
        export DEBIAN_FRONTEND=noninteractive
        echo '$nrconf{restart} = "a";' | sudo tee /etc/needrestart/conf.d/90-no-prompt.conf > /dev/null
        sudo sed -i 's/^Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades 2>/dev/null || true
        sudo apt-get update -qq
        sudo apt-get install -qq -y \
            -o Dpkg::Options::="--force-confdef" \
            -o Dpkg::Options::="--force-confold" \
            wget curl sqlite3 nginx apache2-utils gnupg apt-transport-https
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://archive.heckel.io/apt/pubkey.txt | sudo gpg --dearmor -o /etc/apt/keyrings/archive.heckel.io.gpg
        echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/archive.heckel.io.gpg] https://archive.heckel.io/apt debian main" | \
            sudo tee /etc/apt/sources.list.d/archive.heckel.io.list > /dev/null
        sudo apt-get update -qq
        sudo apt-get install -qq -y ntfy
    elif [[ "$DISTRO" =~ (rhel|centos|fedora|rocky|almalinux|amzn) ]]; then
        sudo yum install -y wget curl sqlite sqlite-devel nginx httpd-tools
        sudo rpm -ivh https://github.com/binwiederhier/ntfy/releases/download/v2.12.0/ntfy_2.12.0_linux_amd64.rpm
    else
        echo "[!] Unsupported distro: $DISTRO"
        exit 1
    fi

    echo "[*] Generating self-signed cert for $PUBLIC_IP"
    sudo mkdir -p "$CERT_DIR"
    cat <<EOF | sudo tee "$CERT_DIR/ip.cnf"
[ req ]
default_bits       = 2048
prompt             = no
distinguished_name = dn
req_extensions     = req_ext

[ dn ]
CN = $PUBLIC_IP

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
IP.1 = $PUBLIC_IP
EOF

    sudo openssl req -x509 -nodes -days 365 \
      -newkey rsa:2048 \
      -keyout "$NTFY_KEY" \
      -out    "$NTFY_CERT" \
      -config "$CERT_DIR/ip.cnf"
    sudo chmod 600 "$NTFY_KEY"

    echo "[*] Configuring nginx"
    sudo tee /etc/nginx/sites-available/ntfy.conf > /dev/null <<EOF
upstream ntfy_backend {
    server 127.0.0.1:8080;
}

server {
    listen 80;
    server_name $PUBLIC_IP;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $PUBLIC_IP;

    ssl_certificate     $NTFY_CERT;
    ssl_certificate_key $NTFY_KEY;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    auth_basic           "ntfy Access";
    auth_basic_user_file $NGINX_HTPASSWD;

    location / {
        add_header Cache-Control "no-store" always;
        add_header Pragma "no-cache" always;
        add_header Expires "0" always;
        proxy_pass         http://ntfy_backend;
        proxy_http_version 1.1;
        proxy_set_header   Host            \$host;
        proxy_set_header   X-Real-IP       \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   Upgrade         \$http_upgrade;
        proxy_set_header   Connection      "upgrade";
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
    }
}
EOF

    sudo ln -sf /etc/nginx/sites-available/ntfy.conf /etc/nginx/sites-enabled/ntfy.conf

    # Hide nginx version properly (add to existing http block)
    sudo sed -i '/http {/a \    server_tokens off;' /etc/nginx/nginx.conf

    sudo nginx -t && sudo systemctl restart nginx

    echo "[*] Writing ntfy config"
    sudo mkdir -p /etc/ntfy /var/cache/ntfy/attachments
    sudo tee "$NTFY_CONFIG" > /dev/null <<EOF
base-url: "https://${PUBLIC_IP}"
listen-http: "127.0.0.1:8080"
listen-https: "127.0.0.1:8443"
key-file: "$NTFY_KEY"
cert-file: "$NTFY_CERT"
auth-file: "$NTFY_DB"
auth-default-access: "deny-all"
cache-file: "/var/cache/ntfy/cache.db"
attachment-cache-dir: "/var/cache/ntfy/attachments"
EOF

    echo "[*] Initializing auth database and creating user"
    sudo touch /var/lib/ntfy/user.db
    sudo sqlite3 "$NTFY_DB" "VACUUM;"

    echo "[+] Enabling and starting ntfy..."
    sudo chmod -R 644 /etc/ssl/ntfy/*
    sudo systemctl enable ntfy
    sudo systemctl start ntfy

    sudo ntfy user add "$NTFY_USER" --pass "$NTFY_PASS" --config "$NTFY_CONFIG"
    sudo sqlite3 "$NTFY_DB" "UPDATE user SET role='admin' WHERE user='$NTFY_USER';"

    echo "[*] Creating nginx htpasswd entry"
    sudo htpasswd -bc "$NGINX_HTPASSWD" "$NTFY_USER" "$NTFY_PASS"

    echo "✅ ntfy is now running at: https://$PUBLIC_IP with user: $NTFY_USER"
}

function add_user() {
    read -p "Enter username to add: " NEW_USER
    read -sp "Enter password: " NEW_PASS
    echo ""
    read -p "Enter topic to allow (only this topic will be accessible): " TOPIC

    sudo ntfy user add "$NEW_USER" --pass "$NEW_PASS" --config "$NTFY_CONFIG"
    sudo ntfy access "$NEW_USER" "$TOPIC" rw --config "$NTFY_CONFIG"
    sudo htpasswd -b "$NGINX_HTPASSWD" "$NEW_USER" "$NEW_PASS"
    echo "[+] User '$NEW_USER' added with access to topic '$TOPIC'"
}

function remove_user() {
    read -p "Enter username to remove: " DEL_USER
    sudo ntfy user del "$DEL_USER" --config "$NTFY_CONFIG"
    sudo sed -i "/^${DEL_USER}:/d" "$NGINX_HTPASSWD"
    echo "[+] User '$DEL_USER' removed."
}

function list_users() {
    echo "[+] Registered Users:"
    sudo sqlite3 "$NTFY_DB" "SELECT user FROM user WHERE deleted IS NULL;"
}

function change_password() {
    read -p "Enter username: " USER
    read -sp "Enter new password: " NEW_PASS
    echo ""
    sudo ntfy user change-pass "$USER" --pass "$NEW_PASS" --config "$NTFY_CONFIG"
    sudo htpasswd -b "$NGINX_HTPASSWD" "$USER" "$NEW_PASS"
    echo "[+] Password changed for '$USER'"
}

function change_role() {
    read -p "Enter username: " USER
    read -p "Enter new role (admin/user): " ROLE
    sudo ntfy user change-role "$USER" "$ROLE" --config "$NTFY_CONFIG"
    echo "[+] Role changed for '$USER' to '$ROLE'"
}

function reset_access() {
    read -p "Enter username: " USER
    sudo ntfy access --reset "$USER" --config "$NTFY_CONFIG"
    echo "[+] Access reset for '$USER'"
}

function show_help() {
    echo "
Usage: $0 <command>"
    echo "
Available commands:"
    echo "  install      - Install ntfy with HTTPS, nginx, and authentication"
    echo "  add-user     - Add a new user with topic access"
    echo "  remove-user  - Remove a user from ntfy and htpasswd"
    echo "  list-users   - List existing users"
    echo "  change-pass  - Change password for an existing user"
    echo "  change-role  - Change user role (admin/user)"
    echo "  reset-access - Reset all topic access for a user"
    echo "  help         - Show this help message"
    echo "
Examples:"
    echo "  sudo $0 install"
    echo "  sudo $0 add-user"
    echo "  sudo $0 remove-user"
    echo "  sudo $0 list-users"
    echo "  sudo $0 change-pass"
    echo "  sudo $0 change-role"
    echo "  sudo $0 reset-access"
}

case "$1" in
  change-pass)
    change_password
    ;;
  change-role)
    change_role
    ;;
  reset-access)
    reset_access
    ;;
  install)
    install_ntfy
    ;;
  add-user)
    add_user
    ;;
  remove-user)
    remove_user
    ;;
  list-users)
    list_users
    ;;
    help)
    show_help
    ;;
  *)
    echo "Usage: $0 {install|add-user|remove-user|list-users|change-pass|change-role|reset-access|help}"
    exit 1
    ;;
esac
