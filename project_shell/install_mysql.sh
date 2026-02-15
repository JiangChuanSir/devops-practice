#!/bin/bash
set -euo pipefail

# ===================== 配置项（可根据需求修改） =====================
# MySQL服务名（CentOS 9 统一为 mysqld）
MYSQL_SERVICE="mysqld"
# MySQL日志路径
MYSQL_LOG="/var/log/mysqld.log"
# 安装版本（CentOS 9 仅支持 MySQL 8.0+）
MYSQL_VERSION="8.0"

# ===================== 前置检查 =====================
# 检查是否为root用户
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：请使用root用户运行此脚本！" >&2
    exit 1
fi

# 检查是否为CentOS 9
if ! grep -q "CentOS Linux release 9" /etc/redhat-release; then
    echo "警告：此脚本适配CentOS 9，当前系统可能不兼容！" >&2
    read -p "是否继续执行？(y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# ===================== 安装依赖与配置仓库 =====================
# 安装必要依赖
dnf install -y wget curl policycoreutils-python-utils

# 配置MySQL官方仓库（适配CentOS 9）
wget https://dev.mysql.com/get/mysql80-community-release-el9-3.noarch.rpm
dnf install -y mysql80-community-release-el9-3.noarch.rpm

# 禁用系统默认的MySQL模块（CentOS 9特有）
dnf module disable -y mysql

# ===================== 安装MySQL服务 =====================
echo "开始安装MySQL $MYSQL_VERSION..."
dnf install -y mysql-community-server --nogpgcheck

# ===================== 启动并设置开机自启 =====================
systemctl start "$MYSQL_SERVICE"
systemctl enable "$MYSQL_SERVICE"

# 等待服务完全启动
sleep 5

# ===================== 获取临时密码 =====================
# MySQL 8.0 临时密码提取规则（CentOS 9 日志格式略有变化）
temp_pass=$(grep 'A temporary password is generated for root@localhost' "$MYSQL_LOG" | awk '{print $NF}')

if [ -z "$temp_pass" ]; then
    echo "错误：未能提取到MySQL临时密码！" >&2
    echo "请手动查看日志：cat $MYSQL_LOG"
    exit 1
fi
echo "MySQL临时密码：$temp_pass"

# ===================== 交互式设置新密码 =====================
read -s -p "请输入新的MySQL root密码（需包含大小写、数字、特殊字符）：" new_pass
echo
read -s -p "请再次输入新密码：" new_pass_confirm
echo

if [ "$new_pass" != "$new_pass_confirm" ]; then
    echo "错误：两次输入的密码不一致！" >&2
    exit 1
fi

# ===================== 安全加固 =====================
echo "开始执行MySQL安全加固..."
mysql -uroot -p"$temp_pass" --connect-expired-password <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$new_pass';
# 删除空用户
DELETE FROM mysql.user WHERE User='';
# 只保留localhost的root用户
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
# 删除测试数据库
DROP DATABASE IF EXISTS test;
# 刷新权限
FLUSH PRIVILEGES;
EOF

# ===================== 验证安装 =====================
echo "验证MySQL安装是否成功..."
if mysql -uroot -p"$new_pass" -e "SELECT VERSION();" > /dev/null 2>&1; then
    echo "====================="
    echo "MySQL安装成功！"
    echo "版本信息：$(mysql -uroot -p"$new_pass" -e "SELECT VERSION();" 2>/dev/null | grep -v VERSION)"
    echo "新密码：$new_pass（请妥善保存）"
    echo "====================="
else
    echo "错误：MySQL安装验证失败！" >&2
    exit 1
fi

# 清理临时文件
rm -f mysql80-community-release-el9-3.noarch.rpm
