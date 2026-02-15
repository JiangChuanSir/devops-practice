#!/bin/bash
# 1. 安装PHP及相关组件
yum install -y epel-release
yum install -y php php-fpm php-mysql

# 2. 启动并设置开机自启
systemctl start php-fpm
systemctl enable php-fpm

# 3. 配置Nginx支持PHP
cat > /etc/nginx/conf.d/php.conf << EOF
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.php index.html;
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

# 4. 重载Nginx
systemctl reload nginx

# 5. 测试PHP
echo "<?php phpinfo(); ?>" > /usr/share/nginx/html/info.php
curl http://localhost/info.php
