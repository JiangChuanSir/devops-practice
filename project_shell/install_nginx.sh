#!/bin/bash
# 1. 安装Nginx
yum install -y nginx

# 2. 启动并设置开机自启
systemctl start nginx
systemctl enable nginx

# 3. 备份默认配置
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak

# 4. 添加虚拟主机配置
echo "server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html index.htm;
}" > /etc/nginx/conf.d/test.conf

# 5. 验证配置
nginx -t

# 6. 重新加载配置
systemctl reload nginx

# 7. 验证安装
curl http://localhost
