# Wazuh Integration with NTFY

This lightweight integration allows Wazuh to trigger push notifications to `ntfy` over HTTP(S), sending real-time alerts to subscribed users — either through mobile apps or desktops.

---

## Use Cases

* Receive **critical security alerts** on your phone (e.g., SSH brute-force, file integrity violations)
* Complement Wazuh’s default email or log-based alerting
* Enable **mobile-first incident response** for on-call analysts
* Build a cost-effective push alert pipeline without external services

---

## Architecture

```text
┌────────────┐      ┌───────────────┐      ┌────────────────────┐      ┌────────────┐
│  Wazuh     │ ──▶ │ custom-ntfy.py │ ──▶ │  NGINX Reverse Proxy│ ──▶ │   NTFY App │
│  Manager   │     │ (Python Script)│     │  (SSL + Auth + ACL)│     │ (Web/Mobile)│
└────────────┘      └───────────────┘      └────────────────────┘      └────────────┘
```

* **Wazuh** triggers the integration when matching alerts are raised
* **custom-ntfy.py** pushes formatted alert data to NTFY using HTTP Basic Auth
* **NGINX** terminates TLS and authenticates access
* **NTFY App** (mobile or browser) instantly receives the alert on the subscribed topic

---

## Files in Repo

```bash
integrations/
└── custom-ntfy.py        # Integration script for Wazuh
ntfy.sh                   # Setup script for NTFY + SSL + Auth
```

---

## Setup Instructions

> These steps assume you have a working NTFY instance secured via `ntfy.sh` from this repo.

### 1. Clone and Deploy the Script on Wazuh Server

```bash
git clone https://github.com/yash22091/ntfy-secure-alerting.git
sudo cp ntfy-secure-alerting/integrations/custom-ntfy.py /var/ossec/integrations/
sudo chmod +x /var/ossec/integrations/custom-ntfy.py
```

### 2. Install Python Requirements

```bash
sudo apt install python3-pip -y
pip3 install requests
```

### 3. Configure Wazuh

Edit `/var/ossec/etc/ossec.conf`:

```xml
<integration>
  <name>custom-ntfy.py</name>
  <alert_format>json</alert_format>
  <rule_id>554,100001</rule_id>
  <level>10</level>
  <group>authentication_failures</group>
</integration>
```

You can customize:

* `rule_id`: Target specific Wazuh rule IDs
* `group`: Trigger only for certain alert types
* `level`: Minimum severity level to trigger

### 4. Restart Wazuh Manager

```bash
sudo systemctl restart wazuh-manager
```

---

## Mobile Notification Flow

1. Install the [ntfy app](https://ntfy.sh/app) on Android or iOS
2. Subscribe to the topic (e.g., `alerts`)
3. When a Wazuh alert matches, your phone receives the push instantly

This removes the need to monitor dashboards or email alerts constantly.

---

## Example Alert Notification

```markdown
**Host**: myserver-01
**Rule ID**: 554 • **Level**: 10
**Description**: SSH brute-force attack detected
```

---

## Requirements

* Wazuh 4.x+
* Python 3 with `requests` installed
* Your NTFY server must be publicly reachable with HTTPS & basic auth

---

## Recommended Improvements

* Subscribe different teams to different topics
* Add a filter to `custom-ntfy.py` to check alert source or geolocation
* Use multiple `group` parameters for flexible routing
* Integrate with Suricata or Falco in addition to Wazuh

---

## Security Considerations

* Passwords are embedded in `custom-ntfy.py`. Use environment variables or secrets management in production
* Only HTTPS should be used
* NGINX + htpasswd adds protection against unauthorized posting/viewing

---

## Related

* [NTFY Official Docs](https://ntfy.sh/docs/)
* [NTFY Android App](https://play.google.com/store/apps/details?id=io.heckel.ntfy)
* [Project GitHub Repo](https://github.com/yash22091/ntfy-secure-alerting)

---

Maintained by: [@yash22091](https://github.com/yash22091)
License: MIT

Let me know if you’d like the version for `ntfy.sh` setup or mobile deployment walkthrough too.
