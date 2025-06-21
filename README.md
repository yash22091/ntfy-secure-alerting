---
NTFY Secure Alerting

A hardened, self-hosted real-time alerting platform using NTFY, powered by:

    HTTPS + Auth via NGINX reverse proxy

    Role-based ACLs

    Wazuh + SIEM integration

    Push to mobile via NTFY app
---

## What Does This Provide?

This repo includes:

* `ntfy.sh`: Fully automated install script for hardened NTFY setup
* `custom-ntfy.py`: Python script to integrate Wazuh alerts
* `README.md`: Setup guide for NTFY and Wazuh integration
* Support for mobile push notifications and access control

---

## Tech Stack Overview

| Component   | Purpose                                     |
| ----------- | ------------------------------------------- |
| NTFY Server | Real-time notification broker               |
| NGINX       | SSL termination + Basic Auth                |
| SQLite      | Auth DB + Access control                    |
| `htpasswd`  | Per-user credential file for reverse proxy  |
| Wazuh SIEM  | Triggers alert JSON → custom Python script  |
| Mobile App  | Receives push alerts via topic subscription |

---

## Getting Started

### Clone the Repository

```bash
git clone https://github.com/yash22091/ntfy-secure-alerting.git
cd ntfy-secure-alerting
chmod +x ntfy.sh
```

---

## Installation

### Deploy NTFY Server with HTTPS + Auth

```bash
sudo ./ntfy.sh install
```

This script will:

* Install NTFY + dependencies
* Auto-configure NGINX reverse proxy
* Generate a **self-signed SSL certificate** OR use **Let's Encrypt**
* Create `.htpasswd`-based authentication
* Configure NTFY’s internal access control via SQLite
* Create your first admin user

---

## User Management (Admin/Topic-Specific)

All managed via the script:

| Task                    | Command                       |
| ------------------------| ----------------------------- |
| Add user with topic ACL | `sudo ./ntfy.sh add-user`     |
| Change password         | `sudo ./ntfy.sh change-pass`  |
| Change user role        | `sudo ./ntfy.sh change-role`  |
| Revoke topic access     | `sudo ./ntfy.sh reset-access` |
| Remove user completely  | `sudo ./ntfy.sh remove-user`  |
| List active users       | `sudo ./ntfy.sh list-users`   |

Example:

```bash
# Add a user named 'alice' with access to topic 'alerts'
sudo ./ntfy.sh add-user
```

---

## Wazuh Integration Setup

1. Copy the script to your Wazuh manager:

```bash
sudo cp integrations/custom-ntfy.py /var/ossec/integrations/
chmod +x /var/ossec/integrations/custom-ntfy.py
```

2. Install Python requirements:

```bash
pip3 install requests
```

3. Modify Wazuh `/var/ossec/etc/ossec.conf`:

```xml
<integration>
  <name>custom-ntfy</name>
  <command>custom-ntfy.py</command>
  <alert_format>json</alert_format>
  <level>10</level>
  <group>authentication_failures</group>
  <rule_id>554,100001</rule_id>
</integration>
```

4. Restart Wazuh:

```bash
sudo systemctl restart wazuh-manager
```

5. Done! Matching alerts will now be **pushed to NTFY**.

---

## Mobile Use Case

Once deployed, install the [ntfy Android/iOS app](https://ntfy.sh/app/) and subscribe to the topic:

```bash
https://your-public-ip-or-domain/alerts
```

> Every alert is pushed as a **real-time notification** to your mobile.

### Why It's Useful:

| Feature                    | Benefit                                   |
| ---------------------------| ----------------------------------------- |
| Real-time security alerts  | No delay, no email parsing                |
| Mobile-first SOC readiness | Alerts without dashboards or SIEM access  |
| Authenticated delivery     | Prevent unauthorized message publishing   |
| Topic-based routing        | On-call engineer sees only what they need |

---

## Architecture Diagram

```
┌────────────┐      ┌───────────────┐      ┌────────────────────┐      ┌────────────┐
│  Wazuh     │ ──▶ │ custom-ntfy.py │ ──▶ │  NGINX Reverse Proxy│ ──▶ │   NTFY App │
│  Manager   │     │ (Python Script)│     │  (SSL + Auth + ACL)│     │ (Web/Mobile)│
└────────────┘      └───────────────┘      └────────────────────┘      └────────────┘
```

---

## Repo Structure

```bash
ntfy-secure-alerting/
├── ntfy.sh              # Installer for NTFY + NGINX + SSL + ACL
├── integrations/
│   └── custom-ntfy.py   # Wazuh integration script (Python)
├── examples/
│   └── ossec.conf       # Wazuh config sample
└── README.md
```

---

## Security Highlights

* HTTPS via OpenSSL or Let's Encrypt
* Auth via NGINX + `htpasswd`
* Anonymous publish denied by default
* Per-topic write-only ACLs for users
* SQLite-based role + access control
* NGINX headers disable browser caching

---

## Requirements

* A Linux server with root access
* Public IP or domain for HTTPS
* Wazuh 4.x manager (optional)
* Python3 & pip (on Wazuh side only)

---

## Contributing

Pull requests, improvements, and topic enhancements welcome!
Feel free to open issues for bugs or suggestions.

---

## License

MIT License © [yash22091](https://github.com/yash22091)

---

