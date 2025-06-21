#!/usr/bin/env python3
import json
import sys
import time
import os

try:
    import requests
    from requests.auth import HTTPBasicAuth
except Exception as e:
    print("No module 'requests' found. Install: pip install requests")
    sys.exit(1)


debug_enabled = True
pwd = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
json_alert = {}
now = time.strftime("%a %b %d %H:%M:%S %Z %Y")

# Set paths
log_file = '{0}/logs/integrations.log'.format(pwd)

alert_file = sys.argv[1]
#api_key = sys.argv[2]

alert_json = json.load(open(alert_file))

username = "username"
password = "password"
ntfy_url = "https://IP"
topic = "topicname"


def debug(msg):
    if debug_enabled:
        msg = "{0}: {1}\n".format(now, msg)
        print(msg)
        f = open(log_file, "a")
        f.write(msg)
        f.close()

def make_request(alert_data):
    url = f"{ntfy_url}/{topic}"
    auth = HTTPBasicAuth(username, password)

    #_data = json.dumps(alert_json["_source"]["data"],indent=4)
    headers = {
     "Title": f'{alert_json["rule"]["description"]} Rule id:{alert_json["rule"]["id"]}',
     "Priority": "urgent",
     "Tags": "warning,skull",
     "Markdown": "yes"
}

    message = f'Immediate Attention Required: An alert has been generated with a rule level of {alert_json["rule"]["level"]} and with rule id of {alert_json["rule"]["id"]}. Prompt review and action are advised.'
    try:
        response = requests.post(url, headers=headers,data=message, auth=auth, verify=False)

        if response.status_code == 200:
            debug(f"Message sent successfully. status_code: {response.status_code}")
        else:
            debug(f"Failed to send message, status code: {response.status_code}")
    except Exception as e:
        debug(f"Request failed. reason: {response.text}\n status_code: {response.status_code}")


make_request(alert_json)
