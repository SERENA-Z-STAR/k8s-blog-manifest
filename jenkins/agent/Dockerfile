# Jenkins 动态 Agent 镜像：基础 agent + helm + kubectl + docker CLI
# docker CLI 从 docker:24-cli 拷贝（避免网络下载），docker 操作走宿主 docker.sock
FROM jenkins/inbound-agent:latest AS base

FROM docker:27-cli AS dockercli

FROM base
USER root

# 基础工具
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates gnupg git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# docker CLI
COPY --from=dockercli /usr/local/bin/docker /usr/local/bin/docker

# helm（get.helm.sh 国内可达）
RUN curl -fsSL https://get.helm.sh/helm-v3.16.4-linux-amd64.tar.gz | tar -xz -C /tmp \
    && mv /tmp/linux-amd64/helm /usr/local/bin/helm \
    && rm -rf /tmp/linux-amd64

# kubectl（阿里云 apt 源，与集群同版本 1.28）
RUN curl -fsSL https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends kubectl=1.28.2-00 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

USER jenkins
