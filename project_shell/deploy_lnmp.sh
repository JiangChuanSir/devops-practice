#!/bin/bash
# 1. 调用各子脚本，并检查返回值
./install_nginx.sh || exit 1
./install_mysql.sh || exit 1
./install_php.sh || exit 1

# 2. 添加状态检查函数
check_service() {
    if systemctl is-active $1 >/dev/null 2>&1; then
        echo "$1 is running"
    else
        echo "$1 is NOT running"
    fi
}

# 3. 检查服务状态
check_service nginx
check_service mysqld
check_service php-fpm

echo "LNMP deployment completed."
