# Terraform 学习模板

模拟阿里云 K8s 集群基础设施（1 主 2 从 ECS + 安全组），用于学习 **IaC（基础设施即代码）** 思想。

## 说明

- 本地 VMware 环境无法真实创建云资源，此模板**仅用于学习**，不执行 `terraform apply`
- 对应关系：本地 3 节点 VMware 虚拟机 = 3 台阿里云 ECS
- 有云账号时可配置 `ALICLOUD_ACCESS_KEY`/`ALICLOUD_SECRET_KEY` 后执行：

```bash
terraform init
terraform plan    # 预览
terraform apply   # 创建（需填写 vpc_id/vswitch_id 等变量）
```

## 资源清单

| 资源 | 说明 |
|---|---|
| alicloud_instance.k8s_master | 控制面节点（对应 k8s-master） |
| alicloud_instance.k8s_node | 工作节点 ×2（对应 k8s-node01/02） |
| alicloud_security_group.k8s | 安全组：6443 API 端口 + 集群内网互通 |

## 与 Ansible 的分工

- **Terraform**：创建基础设施（云上：ECS/网络；本地：VMware 虚拟机）
- **Ansible**：配置管理（初始化系统、安装 K8s 组件）—— 见 `ansible/init-cluster.yml`
