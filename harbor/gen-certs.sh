#!/usr/bin/env bash
# 生成 Harbor 自签名 CA + 服务器证书
set -e
DIR="$(cd "$(dirname "$0")" && pwd)/certs"
mkdir -p "$DIR"
cd "$DIR"

# 1) 自签名 CA
if [ ! -f ca.crt ]; then
  openssl genrsa -out ca.key 4096 2>/dev/null
  openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 \
    -subj "/CN=Harbor-CA" -out ca.crt
fi

# 2) 服务器私钥 + CSR（SAN 同时包含域名和 IP，方便以后用 IP 访问）
openssl genrsa -out harbor.k8s.local.key 4096 2>/dev/null
openssl req -new -key harbor.k8s.local.key -subj "/CN=harbor.k8s.local" -out server.csr

cat > san.cnf <<'EOF'
subjectAltName=DNS:harbor.k8s.local,DNS:localhost,IP:192.168.80.133,IP:127.0.0.1
EOF

# 3) 用 CA 签发服务器证书
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out harbor.k8s.local.crt -days 3650 -sha256 -extfile san.cnf 2>/dev/null

rm -f server.csr san.cnf
echo "=== 证书生成完毕: $DIR ==="
ls -la "$DIR"
