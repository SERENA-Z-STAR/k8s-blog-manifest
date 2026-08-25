#!/bin/sh
# MySQL 首次初始化：创建应用账号（密码从 Pod 环境变量 DB_PASSWORD 读取，来自 Secret）
# 仅在数据卷为空（首次启动）时执行
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<SQL
CREATE USER IF NOT EXISTS 'links_app'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON links_db.* TO 'links_app'@'%';
FLUSH PRIVILEGES;
SQL
