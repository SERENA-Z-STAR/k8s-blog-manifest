variable "region" {
  description = "阿里云地域"
  default     = "cn-hangzhou"
}

variable "instance_type" {
  description = "ECS 规格（对应本地 2C4G 节点）"
  default     = "ecs.c6.large"
}

variable "image_id" {
  description = "系统镜像（Ubuntu 22.04）"
  default     = "ubuntu_22_04_x64_20G_alibase_20231218.vhd"
}

variable "vpc_id" {
  description = "VPC ID（执行前填写）"
  default     = ""
}

variable "vswitch_id" {
  description = "交换机 ID（执行前填写）"
  default     = ""
}

variable "cluster_cidr" {
  description = "集群内网网段（模拟 VMware NAT 网段）"
  default     = "192.168.80.0/24"
}

variable "node_count" {
  description = "工作节点数量（文档规划 2 个）"
  default     = 2
}

variable "instance_password" {
  description = "实例登录密码（生产用密钥对）"
  default     = ""
  sensitive   = true
}
