#!/usr/bin/env bash
set -e

# 1) 禁用 cloud-init 接管网络（防止重启后配置被覆盖）
mkdir -p /etc/cloud/cloud.cfg.d
echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg

# 2) 写静态 IP 配置（覆盖 50-cloud-init.yaml 的 dhcp4: true）
cat > /etc/netplan/99-static.yaml <<'YAML'
network:
  version: 2
  ethernets:
    ens33:
      dhcp4: false
      addresses: [192.168.80.133/24]
      routes: [{to: default, via: 192.168.80.2}]
      nameservers: {addresses: [223.5.5.5, 114.114.114.114]}
YAML
chmod 600 /etc/netplan/99-static.yaml

# 3) 应用
netplan apply

# 4) 验证
echo "--- 验证 ---"
ip -4 addr show ens33 | grep inet
ping -c1 baidu.com
