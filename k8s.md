# K8s云原生博客平台｜新项目完整实现路线

> 背景：你现有博客：VMware‑Ubuntu + Docker‑Compose + GitHub Actions（私有Runner，私有仓库） 目标：**全新做一套K8s版本项目，不改造旧博客**，完全新环境、新代码仓库，全部代码配置上传公开GitHub，简历直接贴链接；模拟中小企业线上业务，覆盖JD高频技能：K8s、Helm、Harbor、Jenkins、Terraform、Ansible、监控告警、故障演练、运维文档。 环境方案：本地VMware 搭建3节点K8s集群（1主2从），不用买云服务器，全部本地虚拟机完成，硬件压力可控。

## 📋项目整体架构

- 业务组件：Nginx前端Web + Node.js后端API + MySQL + Redis
- K8s资源：Namespace、Deployment、Service、Ingress、ConfigMap、Secret、HPA、PodDisruptionBudget
- 镜像仓库：Harbor私有镜像仓库部署在K8s内部
- CI/CD：Jenkins（部署在K8s）完成流水线；替代你私有GitHub Runner
- IaC：Terraform 管理虚拟机网络资源；Ansible做集群初始化批量配置
- 监控告警：Prometheus+Grafana+Loki；告警推送（邮件/企业微信webhook模拟告警）
- 存储：LocalPV模拟本地存储，模拟生产持久化；模拟数据备份
- 配套产出：运维SOP、巡检脚本、故障演练案例、故障复盘文档，全部存GitHub仓库

> 项目仓库拆分建议（GitHub新建公开仓库） `k8s‑blog‑manifest`：全部k8s yaml、helm chart、terraform、ansible playbook、运维脚本、文档（简历重点展示仓库） `k8s‑blog‑web`：博客前后端业务代码（简单复用你原有博客业务即可）

------

# 阶段0｜环境准备（1‑2天）

### 0.1 虚拟机规划（VMware）

| 节点       | 角色     | 配置  | IP规划         |
| ---------- | -------- | ----- | -------------- |
| k8s‑master | 控制平面 | 2C‑4G | 192.168.137.10 |
| k8s‑node01 | 工作节点 | 2C‑4G | 192.168.137.11 |
| k8s‑node02 | 工作节点 | 2C‑4G | 192.168.137.12 |

系统：Ubuntu 22.04，关闭swap，设置静态IP，主机名解析，ssh密钥免密登录。

### 0.2 使用Ansible做集群初始化（重点，简历加分）

> 对应JD技能：Ansible自动化批量运维

1. 在自己电脑写Ansible inventory、playbook

2. playbook实现：

   - 关闭swap、加载内核模块、配置sysctl内核参数
   - 批量安装containerd容器运行时
   - 设置hosts主机解析、时间同步chrony

3. 执行playbook一键完成三台机器k8s前置环境初始化

   > ✅产出：ansible playbook全部提交到 `k8s‑blog‑manifest`

### 0.3 kubeadm部署Kubernetes v1.28/v1.29集群

1. kubeadm init初始化master，生成join命令，node节点加入集群

2. 安装Calico CNI网络插件，验证所有节点Ready

3. 安装kubectl补全工具，本地电脑配置kubeconfig远程操作集群

   > ⚠️不要用minikube，minikube简历含金量低；kubeadm多节点更贴近企业真实环境。

------

# 阶段1｜镜像仓库Harbor（1天）JD高频：Harbor私有镜像仓库

> 企业不会把业务镜像放dockerhub，都是私有Harbor仓库

1. 在k8s集群内部，使用helm安装Harbor
2. 创建项目：`blog‑project`，账号密码管理
3. 配置所有node节点containerd信任harbor自签名https证书
4. 测试：手动build一个web镜像，推送到harbor，k8s可以拉取镜像成功。

✅产出：helm values配置文件存入仓库。

------

# 阶段2｜业务应用部署：博客完整上K8s（2‑3天）

> 复用你原有博客业务代码，不用重写业务逻辑，重点在于**K8s资源编排** 命名空间：`blog‑ns`，隔离博客全部资源

## 2.1 编写资源yaml，或者封装Helm Chart（强烈建议用helm，JD大量helm）

业务需要的资源清单：

1. **ConfigMap**：存放nginx配置、应用普通配置（非敏感）
2. **Secret**：MySQL密码、Redis密码，密钥加密存储，**严禁明文写yaml**
3. **StatefulSet**：MySQL、Redis（有状态应用，代替Deployment，学习有状态服务部署）
4. **Deployment**：Web前端、Node后端无状态应用
5. **Service**：ClusterIP，内部组件互相访问
6. **Ingress(Nginx‑ingress‑controller)**：对外入口，域名访问博客 `blog.k8s.local`，本地hosts做域名解析
7. **LocalPV + PersistentVolumeClaim**：MySQL、Redis数据持久化，模拟生产存储
8. **HPA 水平Pod自动扩缩容**：CPU负载高自动增加Pod副本，负载降低缩容
9. **PodDisruptionBudget**：保障滚动更新时最少可用副本，模拟业务高可用

操作流程：

1. 业务代码本地build镜像 → push到内部Harbor仓库
2. helm install部署整套博客
3. 访问 `blog.k8s.local` 验证网站完整可用，读写数据库验证持久化：删除Pod，数据不会丢失。

✅产出：完整helm chart全部放入 `k8s‑blog‑manifest` 仓库。

> 练习故障操作（必做，简历故障排查素材）
>
> - 手动删除Pod，观察控制器自动重建Pod
> - 调高HPA压力测试，观察Pod自动扩容缩容
> - 修改镜像版本模拟业务滚动更新，观察滚动升级；模拟版本出错执行rollback回滚。

------

# 阶段3｜CI/CD流水线搭建：Jenkins on K8s（2‑3天）

> 替代你之前私有GitHub Runner，JD高频：Jenkins流水线

## 3.1 在K8s内部部署Jenkins

1. helm安装jenkins，使用PersistentVolume持久化jenkins数据
2. Jenkins配置：
   - 配置kubeconfig，Jenkins可以直接操作K8s集群
   - 配置Harbor凭证（账号密码）
   - 配置git凭证，拉取业务代码仓库

## 3.2 编写Jenkinsfile流水线（Pipeline as Code，存业务代码仓库）

流水线完整步骤：

```
1. Checkout SCM：拉取博客web业务源码
2. 代码静态简单检查（shell做简单lint）
3. Build镜像：docker build构建业务镜像
4. Push镜像：打上git commit版本标签，推送到内部Harbor私有仓库
5. Helm升级部署：helm upgrade 更新k8s里面博客应用版本
6. 部署后健康检查：调用博客健康接口，确认新版本服务正常
7. 失败处理：部署失败自动执行helm rollback回滚上一个稳定版本
```

### ✅演示完整流程

修改博客前端代码 → git push代码仓库 → Jenkins自动触发流水线 → 自动构建推送镜像 → helm升级k8s应用 → 浏览器看到网站更新。

> 对比你旧方案：旧方案是私有runner ssh远程刷新VMware；新项目是标准企业Jenkins+helm的交付模式。

✅产出：Jenkinsfile、jenkins helm配置提交仓库。

------

# 阶段4｜IaC + 自动化运维：Terraform + Ansible（2天）JD高频Terraform

> Terraform：基础设施即代码；Ansible：配置管理

1. **Terraform**：写tf文件，模拟管理虚拟机网络资源（静态IP、主机名）；

   > 本地VMware可以用vmware provider；没有条件就写**模拟云资源tf模板**（阿里云ECS、安全组），注释说明用于学习IaC思想。 简历描述：掌握Terraform IaC，通过代码定义基础设施资源，避免手动点击操作。

2. **Ansible扩展** 新增playbook实现：

- 批量集群巡检脚本：收集节点CPU、内存、Pod状态输出报告
- 数据库定时备份脚本：MySQL定时备份，备份文件保存到本地PV存储。

✅产出：tf全部代码，ansible巡检&备份脚本上传仓库。

------

# 阶段5｜监控、日志、告警体系（2天）

> 复用你已经会的Prometheus+Grafana+Loki，部署到本套k8s集群

1. helm安装kube‑prometheus‑stack，全套监控栈

   - node‑exporter采集虚拟机节点指标
   - kube‑state‑metrics采集k8s集群资源指标
   - Loki收集集群全部Pod容器日志

2. 导入现成grafana看板：K8s集群大盘、节点大盘、MySQL监控大盘

3. 配置告警规则

   ：

   - 节点CPU内存过高、Pod异常崩溃、Deployment副本丢失、MySQL服务不可用触发告警
   - 使用webhook模拟告警（企业微信机器人），模拟7*24告警通知。

> 动手制造故障，验证告警：手动kill mysql pod，等待收到告警消息。

✅产出：告警规则、grafana dashboard json导出，上传git。

------

# 阶段6｜故障演练 + 全套运维文档（最重要，简历核心亮点 2‑3天）

> 大量JD看重：故障处理、复盘、SOP文档。全部文档写Markdown，放到github仓库docs文件夹。

### 需要写的文档清单（全部必须产出）

1. `docs/部署手册.md`：项目架构图、环境说明、全新环境完整部署步骤
2. `docs/运维SOP.md`：日常巡检操作、版本发布流程、版本回滚操作手册、数据库备份恢复操作
3. `docs/故障演练&复盘报告.md`（重点！简历可以直接写这个成果） 人为制造下面故障，记录现象、排查步骤、根因、解决方案、优化方案：

- 演练1：Pod镜像拉取失败，应用无法启动

- 演练2：MySQL Pod异常CrashLoopBackOff

- 演练3：节点CPU打满，集群告警

- 演练4：Ingress配置错误，网站访问404

  > 每一个故障：现象 → 排查命令（kubectl describe / kubectl logs） → 定位根因 → 修复动作 → 后续如何避免该故障。模拟真实生产故障复盘。

1. `docs/项目总结.md`：技术栈清单，学到的能力，对标岗位JD的哪些技能。

------

# 阶段7｜仓库整理 + 简历如何描写该项目

> GitHub仓库目录参考

```
k8s-blog-manifest
├── ansible/           # ansible初始化playbook、巡检备份脚本
├── terraform/         # terraform IaC代码
├── helm-chart/blog‑chart  #博客helm完整chart
├── jenkins/           # jenkins配置、Jenkinsfile
├── monitoring/        # prometheus规则、grafana看板json
├── docs/              # 全套md文档：部署手册、SOP、故障复盘报告
└── README.md          # 项目总说明：架构图、环境、功能演示截图、快速上手
```

## ✨简历项目描述参考（可以直接复制修改）

> **K8s云原生博客平台｜模拟企业业务云原生项目** 技术栈：Kubeadm‑K8s、Helm、Harbor、Jenkins、Ansible、Terraform、Prometheus+Grafana+Loki、Ingress、HPA 项目环境：VMware虚拟机3节点Kubernetes集群，实现一套完整云原生博客业务。
>
> - 使用kubeadm搭建多节点K8s集群，Helm封装业务Chart；使用StatefulSet部署MySQL/Redis有状态服务，Ingress做流量入口，HPA实现Pod弹性扩缩容，LocalPV完成数据持久化。
> - 部署Harbor私有镜像仓库管理业务镜像；基于Jenkins Pipeline实现CI/CD流水线：代码提交自动构建镜像、推送到Harbor、Helm升级部署，部署失败自动回滚版本。
> - 使用Ansible完成集群节点批量初始化、编写自动化巡检与数据库备份脚本；Terraform实践IaC基础设施即代码思想。
> - 部署Prometheus+Grafana+Loki监控日志栈，配置集群、业务告警规则，模拟故障触发告警通知。
> - 完成多场景故障演练，输出完整部署手册、运维SOP、故障复盘文档，沉淀到GitHub。

------

# ⏱️时间预估 & 踩坑提醒

1. 总耗时：如果每天2‑3小时，**两周左右完整做完**；优先保证K8s业务+Jenkins流水线，Terraform、故障文档是加分项。
2. 坑1：VMware资源不够，可以调低虚拟机内存，优先保证master+2node；
3. 坑2：不要把大业务镜像提交git，git只存yaml、chart、脚本、文档；镜像存在本地Harbor。
4. 坑3：Secret密钥不要明文上传github！演示环境可以注释提醒，实际使用外部密钥管理。

## 可选拓展（时间充裕再做，不强制）

1. 增加Gitlab‑CI流水线做备选CI方案；
2. 模拟金丝雀发布（Canary）；
3. 学习OPA安全策略，简单了解集群安全。

如果你需要，我可以帮你输出一份 `README.md` 模板、或者故障复盘文档的模板，直接复制进项目使用。