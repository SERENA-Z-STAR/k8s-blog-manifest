# ============================================================
# Terraform 学习模板：模拟阿里云 ECS 资源
# 说明：
#   - 本地 VMware 环境无法真实创建云资源，此模板用于学习 IaC 思想
#   - 有云账号时可执行 terraform init/plan/apply（需配置阿里云凭证）
#   - 与本项目的关系：文档规划 3 节点集群（master+2node）对应 3 台 ECS
# ============================================================

# 阿里云 Provider（学习用，不实际执行）
terraform {
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1.230.0"
    }
  }
}

# 配置区（执行前替换为真实凭证或使用环境变量 ALICLOUD_ACCESS_KEY / ALICLOUD_SECRET_KEY）
provider "alicloud" {
  region = var.region
}

# ---------- 安全组：K8s 集群节点 ----------
resource "alicloud_security_group" "k8s" {
  name        = "k8s-cluster-sg"
  description = "K8s 集群节点安全组（模拟 3 节点集群网络隔离）"
  vpc_id      = var.vpc_id
}

# 控制面端口（6443 API Server）
resource "alicloud_security_group_rule" "k8s_apiserver" {
  security_group_id = alicloud_security_group.k8s.id
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "6443/6443"
  cidr_ip           = "0.0.0.0/0"
  description       = "K8s API Server"
}

# 节点互通（内网全放行：Pod 网络/NodePort）
resource "alicloud_security_group_rule" "k8s_internal" {
  security_group_id = alicloud_security_group.k8s.id
  type              = "ingress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  cidr_ip           = var.cluster_cidr
  description       = "集群内网互通（对应本地 VMware NAT 网段）"
}

# ---------- ECS 实例：1 主 2 从 ----------
resource "alicloud_instance" "k8s_master" {
  instance_name        = "k8s-master"
  instance_type        = var.instance_type
  image_id             = var.image_id
  vswitch_id           = var.vswitch_id
  security_groups      = [alicloud_security_group.k8s.id]
  system_disk_category = "cloud_essd"
  system_disk_size     = 40
  password             = var.instance_password

  user_data = <<-EOF
    #!/bin/bash
    # 对应本地阶段的 Ansible init-cluster.yml（关swap/内核参数/containerd/kubeadm）
    # 生产环境建议用 cloud-init + Ansible 完成初始化
    swapoff -a
    echo '{"network":{"config":"disabled"}}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
  EOF

  tags = {
    Role    = "control-plane"
    Project = "k8s-blog"
  }
}

resource "alicloud_instance" "k8s_node" {
  count                = var.node_count
  instance_name        = "k8s-node0${count.index + 1}"
  instance_type        = var.instance_type
  image_id             = var.image_id
  vswitch_id           = var.vswitch_id
  security_groups      = [alicloud_security_group.k8s.id]
  system_disk_category = "cloud_essd"
  system_disk_size     = 40
  password             = var.instance_password

  tags = {
    Role    = "worker"
    Project = "k8s-blog"
  }
}
