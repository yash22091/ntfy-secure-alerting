# NTFY Secure Alerting 🚨🔐

A hardened, self-hosted alerting stack built with:

- 🔔 NTFY for real-time notifications
- 🛡️ NGINX reverse proxy with HTTPS + auth
- 📲 Mobile push via `ntfy` apps
- ⚙️ Wazuh integration for security events

## Features
- 🔐 SSL + Basic Auth secured
- ✅ Scripted deployment (install, add-user, change-pass, etc.)
- 📦 Wazuh → NTFY via custom Python integration
- 💬 Multi-user topic-specific access
- 📱 Push notifications via ntfy Android/iOS app

## Get Started
```bash
git clone https://github.com/your-org/ntfy-secure-alerting.git
cd ntfy-secure-alerting
sudo ./ntfy.sh install
