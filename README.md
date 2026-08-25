# k8s-blog-manifest

K8s 云原生平台项目 - 基础设施即代码仓库（业务代码见 [k8s-blog-web](../k8s-blog-web)）

## 项目架构

```
用户 → Ingress(https://share.k8s.local:32443)
      → ingress-nginx → links-nginx(静态层) → links-app(Node+EJS)
      → links-mysql(StatefulSet+LocalPV) / links-redis(StatefulSet)
镜像仓库：Harbor（集群内）  CI/CD：Jenkins（集群内）
监控：Prometheus+Grafana+Loki（阶段5）
```

- 环境：单节点 kubeadm v1.28.2（Ubuntu 22.04，containerd 2.2.1）
- 业务：Links 信息分享站（苹果风轻博客 + 外链分享，管理员后台发布）

## 目录结构

```
├── docs/                  # 部署手册（阶段0-1 / 阶段2）、运维文档
├── helm-charts/links-chart/  # 博客业务 Helm Chart
├── harbor/                # Harbor values + 证书脚本（私钥不入库）
├── ingress/               # ingress-nginx 配置
├── storage/               # local-path-provisioner manifest
└── tls/                   # share.k8s.local 证书（公钥入库，私钥不入库）
```

## 快速开始

```bash
# 1. 集群初始化（见 docs/部署手册-阶段0-1.md）
# 2. 部署业务
helm install links helm-charts/links-chart
# 3. 访问 https://share.k8s.local:32443
```

## 技术栈

kubeadm · containerd · flannel · Helm · Harbor · Jenkins(阶段3) · Ansible(阶段4) · Terraform(阶段4) · Prometheus/Grafana/Loki(阶段5) · Ingress · HPA · LocalPV
