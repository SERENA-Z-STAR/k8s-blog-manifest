#!/bin/sh
# MySQL 首次初始化脚本（挂载到 /docker-entrypoint-initdb.d/）
# blog_app 用户密码从 Pod 环境变量 DB_PASSWORD 读取（来自 K8s Secret），不落明文
# 注意：只在数据卷为空（首次启动）时执行
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<SQL
CREATE USER IF NOT EXISTS 'blog_app'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON my_blog.* TO 'blog_app'@'%';
FLUSH PRIVILEGES;
SQL
