output "master_instance" {
  description = "Master 节点信息"
  value = {
    id   = alicloud_instance.k8s_master.id
    name = alicloud_instance.k8s_master.instance_name
  }
}

output "node_instances" {
  description = "Worker 节点信息"
  value = [
    for i in alicloud_instance.k8s_node :
    { id = i.id, name = i.instance_name }
  ]
}

output "security_group_id" {
  description = "安全组 ID（K8s 端口放行）"
  value       = alicloud_security_group.k8s.id
}
