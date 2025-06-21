# NTFY Secure Alerting 

## Get Started
The script ntfy.sh automates installation and secure configuration of NTFY behind NGINX, including:

HTTPS setup (via OpenSSL or Let's Encrypt)

htpasswd authentication

Role-based access per topic

SQLite access control

Usage

# Clone the repository
git clone https://github.com/your-org/ntfy-secure-alerting.git
cd ntfy-secure-alerting

# Install all components
sudo ./ntfy.sh install       # First-time setup

# Add and manage users
sudo ./ntfy.sh add-user      # Add user with topic access
sudo ./ntfy.sh change-pass   # Update password
sudo ./ntfy.sh change-role   # Promote/demote user
sudo ./ntfy.sh reset-access  # Revoke all topics
sudo ./ntfy.sh remove-user   # Full removal
sudo ./ntfy.sh list-users    # Show active users

A hardened, self-hosted alerting stack built with:

- NTFY for real-time notifications
- NGINX reverse proxy with HTTPS + auth
- Mobile push via `ntfy` apps
- Wazuh integration for security events

## Features
- SSL + Basic Auth secured
- Scripted deployment (install, add-user, change-pass, etc.)
- Wazuh → NTFY via custom Python integration
- Multi-user topic-specific access
- Push notifications via ntfy Android/iOS app
