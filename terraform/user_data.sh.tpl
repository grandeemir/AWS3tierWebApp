#!/bin/bash
set -euxo pipefail

dnf update -y
dnf install -y nginx

cat > /usr/share/nginx/html/index.html <<HTML
<!doctype html>
<html>
  <head><title>Secure 3-tier App</title></head>
  <body>
    <h1>Secure Multi-tier App</h1>
    <p>Served from app tier instance: $(hostname)</p>
  </body>
</html>
HTML

sed -i 's/listen       80;/listen       ${app_port};/' /etc/nginx/nginx.conf
systemctl enable nginx
systemctl restart nginx
