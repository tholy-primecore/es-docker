#!/usr/bin/env bash
# Native Elasticsearch 8.6.1 on Ubuntu 18.04 (primecoredidk / 217.16.177.87)
# Match local es-docker es8: 8.6.1 + lemmagen + hunspell, security off.
#
# Run as root on the server, from a directory that contains:
#   elasticsearch-analysis-lemmagen-8.6.1-plugin.zip
#   shared/hunspell/   (cs_CZ.aff + cs_CZ.dic)
#   shared/lemmagen/cs.lem
#
# Example from laptop (cwd = es-docker/elasticsearch), user primecore:
#   ssh primecore@217.16.177.87 'mkdir -p ~/es8-install'
#   scp install-native-es8-ubuntu18.sh \
#       es8/elasticsearch-analysis-lemmagen-8.6.1-plugin.zip \
#       primecore@217.16.177.87:~/es8-install/
#   scp -r shared primecore@217.16.177.87:~/es8-install/
#   ssh -t primecore@217.16.177.87 'cd ~/es8-install && sudo bash install-native-es8-ubuntu18.sh'
#
# Install itself must run as root (apt + systemd). Staging files live in ~/es8-install.

set -euo pipefail

ES_VERSION="${ES_VERSION:-8.6.1}"
HEAP="${ES_HEAP:-2g}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root." >&2
  exit 1
fi

need() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    echo "Missing required path: $path" >&2
    exit 1
  fi
}

need "${SCRIPT_DIR}/elasticsearch-analysis-lemmagen-${ES_VERSION}-plugin.zip"
need "${SCRIPT_DIR}/shared/hunspell/cs_CZ/cs_CZ.aff"
need "${SCRIPT_DIR}/shared/hunspell/cs_CZ/cs_CZ.dic"
need "${SCRIPT_DIR}/shared/lemmagen/cs.lem"

echo "==> Stopping / removing Elasticsearch 5 if present"
systemctl stop elasticsearch 2>/dev/null || true
systemctl disable elasticsearch 2>/dev/null || true
apt-get remove -y elasticsearch 2>/dev/null || true
apt-get purge -y elasticsearch 2>/dev/null || true
rm -rf /var/lib/elasticsearch /var/log/elasticsearch /etc/elasticsearch /usr/share/elasticsearch

echo "==> Kernel vm.max_map_count"
sysctl -w vm.max_map_count=262144
mkdir -p /etc/sysctl.d
echo 'vm.max_map_count=262144' >/etc/sysctl.d/99-elasticsearch.conf

echo "==> Elastic APT repo (8.x) + pin ${ES_VERSION}"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y apt-transport-https gnupg wget ca-certificates
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main' \
  >/etc/apt/sources.list.d/elastic-8.x.list
apt-get update
# Force maintainer configs on upgrade from ES5; we overwrite elasticsearch.yml next.
apt-get install -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confnew" \
  "elasticsearch=${ES_VERSION}"
systemctl stop elasticsearch 2>/dev/null || true

echo "==> elasticsearch.yml (single-node, security off)"
cat >/etc/elasticsearch/elasticsearch.yml <<'YAML'
cluster.name: primecore-es8
node.name: es8-217
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node
xpack.security.enabled: false
xpack.security.http.ssl.enabled: false
xpack.security.transport.ssl.enabled: false
YAML

echo "==> Heap ${HEAP}"
sed -i 's/^-Xms.*/-Xms'"${HEAP}"'/' /etc/elasticsearch/jvm.options
sed -i 's/^-Xmx.*/-Xmx'"${HEAP}"'/' /etc/elasticsearch/jvm.options

echo "==> Hunspell + lemmagen lexicon"
mkdir -p /etc/elasticsearch/hunspell/cs_CZ /etc/elasticsearch/lemmagen
cp -a "${SCRIPT_DIR}/shared/hunspell/cs_CZ/." /etc/elasticsearch/hunspell/cs_CZ/
cp -a "${SCRIPT_DIR}/shared/lemmagen/cs.lem" /etc/elasticsearch/lemmagen/cs.lem
chown -R elasticsearch:elasticsearch /etc/elasticsearch/hunspell /etc/elasticsearch/lemmagen

echo "==> Lemmagen plugin ${ES_VERSION}"
# elasticsearch-env sources /etc/default/elasticsearch; must be readable by user elasticsearch.
chown root:elasticsearch /etc/default/elasticsearch
chmod 640 /etc/default/elasticsearch
/usr/share/elasticsearch/bin/elasticsearch-plugin remove analysis-lemmagen 2>/dev/null || true
/usr/share/elasticsearch/bin/elasticsearch-plugin remove elasticsearch-analysis-lemmagen 2>/dev/null || true
PLUGIN_ZIP="${SCRIPT_DIR}/elasticsearch-analysis-lemmagen-${ES_VERSION}-plugin.zip"
/usr/share/elasticsearch/bin/elasticsearch-plugin install --batch "file://${PLUGIN_ZIP}"
chown -R elasticsearch:elasticsearch /usr/share/elasticsearch/plugins

echo "==> Enable + start"
systemctl daemon-reload
systemctl enable elasticsearch
systemctl restart elasticsearch

echo "==> Waiting for HTTP..."
for i in $(seq 1 60); do
  if curl -sf http://127.0.0.1:9200/ >/dev/null; then
    break
  fi
  sleep 2
done

echo "==> Version"
curl -sS http://127.0.0.1:9200/ | python3 -m json.tool | head -30

echo "==> Plugins"
curl -sS 'http://127.0.0.1:9200/_cat/plugins?v'

echo "==> Lemmagen analyze"
curl -sS -X POST 'http://127.0.0.1:9200/_analyze' -H 'Content-Type: application/json' \
  -d '{"tokenizer":"standard","filter":[{"type":"lemmagen","lexicon":"cs"}],"text":"pracovníci nastoupili"}' \
  | python3 -m json.tool

echo "==> Hunspell analyze"
curl -sS -X POST 'http://127.0.0.1:9200/_analyze' -H 'Content-Type: application/json' \
  -d '{"tokenizer":"standard","filter":[{"type":"hunspell","locale":"cs_CZ","dedup":true}],"text":"pracovníky"}' \
  | python3 -m json.tool

echo "Done. Open :9200 from app servers / VPN only."
