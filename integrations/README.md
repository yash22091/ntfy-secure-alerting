Wazuh Integration with NTFY

This integration enables Wazuh to send real-time alerts to NTFY, allowing your SOC team or on-call engineers to receive push notifications on desktop or mobile via the ntfy app.
Use Case

    Push security alerts from Wazuh (e.g., brute-force, malware detection) to subscribed users

    Bypass heavy SIEM dashboards for critical alerts

    Enable mobile-friendly alerting for faster response

Architecture

┌────────────┐      ┌────────────┐      ┌────────────────────┐      ┌────────────┐
│  Wazuh     │ ──▶ │  NTFY.py   │ ──▶ │  NGINX Reverse Proxy │ ──▶ │   NTFY App  │
│  Manager   │     │ Integration│     │  (SSL + Auth + ACL) │     │ (Mobile/Web)│
└────────────┘      └────────────┘      └────────────────────┘      └────────────┘

Files

Place this script on your Wazuh manager server:

/var/ossec/integrations/custom-ntfy.py

Ensure it is executable:

chmod +x /var/ossec/integrations/custom-ntfy.py

Dependencies

Install required Python package on Wazuh:

pip install requests

Configuration

Update your /var/ossec/etc/ossec.conf with:

<integration>
  <name>custom-ntfy</name>
  <command>/var/ossec/integrations/custom-ntfy.py</command>
  <alert_format>json</alert_format>
  <rule_id>554,100001</rule_id>
  <level>10</level>
  <group>authentication_failures</group>
</integration>

Restart Wazuh manager:

systemctl restart wazuh-manager

Mobile Setup (Optional)

    Install ntfy app on your mobile device.

    Subscribe to the same topic used in custom-ntfy.py (e.g., alerts).

    Ensure your NGINX endpoint is accessible from mobile with Basic Auth.

Test It

Manually trigger a test alert:

/var/ossec/integrations/custom-ntfy.py /tmp/sample_alert.json

Or simulate a real alert by raising a rule match in Wazuh.
Security Notes

    Auth credentials and topic settings are defined inside custom-ntfy.py

    Only allow write access to that topic via NTFY access control

    NGINX provides HTTPS + basic auth frontend

    All messages are UTF-8 and Markdown-safe

Integration Example

From a cloned repo (separate from ntfy server):

git clone https://github.com/your-org/ntfy-secure-alerting.git
cp ntfy-secure-alerting/integrations/custom-ntfy.py /var/ossec/integrations/

