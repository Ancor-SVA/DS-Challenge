#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <splunk-download-url> [admin-password]"
  echo "Example: $0 'https://download.splunk.com/.../splunk-9.0.0-a1234bcd-linux-2.6-x86_64.tgz' 'MyS3cretPass'"
  exit 1
fi

SPLUNK_URL="$1"
SPLUNK_ADMIN_PASSWORD="${2:-changeme123!}"

if [[ -z "$SPLUNK_URL" ]]; then
  echo "Error: Splunk download URL is required."
  exit 1
fi

TMPDIR="/tmp/splunk_install_$$"
mkdir -p "$TMPDIR"
TARBALL="$TMPDIR/splunk.tgz"

echo "Downloading Splunk from: $SPLUNK_URL"
if command -v curl >/dev/null 2>&1; then
  curl -L --fail -o "$TARBALL" "$SPLUNK_URL"
else
  wget -O "$TARBALL" "$SPLUNK_URL"
fi

if [[ ! -f "$TARBALL" ]]; then
  echo "Download failed or file not found: $TARBALL"
  exit 1
fi

source /etc/os-release
if [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
  sudo apt-get update
  sudo apt-get install -y libaio1 curl wget
elif [[ "$ID" == "rhel" || "$ID" == "centos" || "$ID" == "fedora" || "$ID_LIKE" == *"rhel"* ]]; then
  sudo yum install -y libaio curl wget
else
  echo "Warning: unknown Linux distribution. Ensure necessary packages are installed manually."
fi

sudo mkdir -p /opt
sudo tar -xzf "$TARBALL" -C /opt

if [[ ! -x /opt/splunk/bin/splunk ]]; then
  echo "Splunk binary not found after extraction."
  exit 1
fi

sudo chown -R root:root /opt/splunk
sudo /opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd "$SPLUNK_ADMIN_PASSWORD"
sudo /opt/splunk/bin/splunk enable boot-start --accept-license --answer-yes --no-prompt

cat <<EOF
Splunk install finished.
- Admin username: admin
- Admin password: $SPLUNK_ADMIN_PASSWORD
- Web UI: http://localhost:8000

To start Splunk manually:
  sudo /opt/splunk/bin/splunk start
To stop Splunk manually:
  sudo /opt/splunk/bin/splunk stop
EOF

rm -rf "$TMPDIR"
