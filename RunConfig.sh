#!/bin/bash
clear
echo -n "Enter Hostname (Leave blank if you do not wish to change current hostname): "
read text
if [ -z "$text"]
then
	echo "Unchanged hostname"
else
	echo "HOSTNAME=$text" >> /etc/sysconfig/network
	hostname "$text"
fi

file="/etc/httpd/conf.d/vhost.conf"

if [ -f "$file" ]
then
  echo "$file Vhost file found."
else
  echo "$file not found. Creating file."
cat > /etc/httpd/conf.d/vhost.conf << EOF1
<VirtualHost *:8080>
     ServerAdmin roddy@orange.mu
     ServerName roddy.wikaba.com
     ServerAlias roddy.wikaba.com
     DocumentRoot /var/www/html/roddy.wikaba.com/public_html/
     ErrorLog /var/www/html/roddy.wikaba.com/logs/error.log
     CustomLog /var/www/html/roddy.wikaba.com/logs/access.log combined
     <Directory />
     AllowOverride All
     </Directory>
</VirtualHost>
EOF1
fi
#echo "You entered: $text"
#nano /etc/httpd/conf.d/vhost.conf
#<VirtualHost *:8080>
#     ServerAdmin roddy@orange.mu
#     ServerName roddy.wikaba.com
#     ServerAlias roddy.wikaba.com
#     DocumentRoot /var/www/html/roddy.wikaba.com/public_html/
#     ErrorLog /var/www/html/roddy.wikaba.com/logs/error.log
#     CustomLog /var/www/html/roddy.wikaba.com/logs/access.log combined
#     <Directory />
#     AllowOverride All
#     </Directory>
#</VirtualHost>

#Configure Nginx
#server {
# listen 80;
#root /var/www/html/roddy.wikaba.com/public_html;
# index index.php index.html index.htm;
#server_name roddy.wikaba.com;
#location / {
# try_files $uri $uri/ /index.php;
# }
#location ~ \.php$ {
#
# proxy_set_header X-Real-IP $remote_addr;
# proxy_set_header X-Forwarded-For $remote_addr;
# proxy_set_header Host $host;
# proxy_pass http://127.0.0.1:8080;
#
#}
#
#location ~ /\.ht {
# deny all;
# }
#}



