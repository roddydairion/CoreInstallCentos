#!/bin/bash
preConfig ()
{
	hostnameDisplay=$(/bin/hostname -f)
	echo -p "Enter Hostname (Leave blank if you do not wish to change current hostname. Current Hostname $hostnameDisplay): "
	read text
	if [ -z "$text" ]
	then
		echo "hostname $hostnameDisplay"
		hNAME="$hostnameDisplay"
	else
		hNAME="$text"
	fi

	echo -n "Enter path to DocumentRoot (/var/www/html/):"
	read text
	if [ -z "$text" ]
	then
		PATH="/var/www/html"
	else
		PATH="$text"
	fi

	while read -p "Enter domain name/project name (eg: example.com, project.example.com): " PROJECT && [[ -z "$PROJECT" ]] ; do
		echo "You need to enter a domain name/project name!"
	done

	while read -p "Enter email address to be configured with project: " EMAIL && [[ -z "$EMAIL" ]] ; do
		echo "You need to enter an email address!"
	done

	echo "Select an IP address to assign to domain name/project name: "
	select ip in $(/sbin/ifconfig | /bin/awk '/inet addr/{print substr($2,6)}'); do 
	if [ "$ip" = "exit" ]
	then
		exit 0
	elif [ -n "$ip" ]
	then
		#echo $ip
		break
	else
		echo "Invalid choice"
	fi
	done
}

writeConfig(){
export PATH=$PATH:/usr/local/bin
preConfig
echo -e "\nHostname            : $hNAME"
echo "DocumentRoot        : $PATH"
echo "Domain/Project name : $PROJECT"
echo "Email               : $EMAIL"
echo -e "IP Assigned         : $ip\n"

echo -n "Are you sure you want to apply the configuration above (Y/n)?"
read text
choice="${text^^}"
if [ $choice == "Y" ]
then

if /bin/grep -q "Listen 80" "/etc/httpd/conf/httpd.conf"
then
	$(/bin/sed -i -e 's/\<Listen 80\>/Listen 8080/g' /etc/httpd/conf/httpd.conf)
else
	echo "Already listening on port 8080"
fi

$(/bin/mkdir -p "$PATH/$PROJECT/public_html/")
$(/bin/mkdir -p "$PATH/$PROJECT/logs/")

if /bin/grep -F "$ip    $PROJECT" "/etc/hosts"
then
	echo "Host already exits"
else
/bin/cat <<EOF >> /etc/hosts
$ip    $PROJECT
EOF
fi

###Configuration of Apache Virtual Host
file="/etc/httpd/conf.d/vhost.conf"

if /bin/grep -F "NameVirtualHost *:8080" "${file}"
then
	echo "Name Virtuals Host exists."
else
 	$(/bin/sed -i '1s/^/NameVirtualHost *:8080\n/' "${file}")
fi

if /bin/grep -q "#Creating apache config for Vhost $PROJECT" "${file}"
then
  echo -e "Existing Apache configuration found for $PROJECT.\nSkipping Configuration on Apache Virtuals Host for $PROJECT\n\n"
else
	/bin/cat <<EOF >> "$file"
#Creating apache config for Vhost $PROJECT
<VirtualHost *:8080>
     ServerAdmin $EMAIL
     ServerName $PROJECT
     ServerAlias $PROJECT
     DocumentRoot $PATH/$PROJECT/public_html/
     ErrorLog $PATH/$PROJECT/logs/error.log
     CustomLog $PATH/$PROJECT/logs/access.log combined
     <Directory />
     AllowOverride All
     </Directory>
</VirtualHost>
EOF
fi


###Configuration of Nginx Virtual host
file="/etc/nginx/conf.d/virtual.conf"

if /bin/grep -q "#Creating nginx config for Vhost $PROJECT" "${file}"
then
  echo -e "Existing Nginx configuration found for $PROJECT.\nSkipping Configuration on Nginx Virtuals Host for $PROJECT\n\n"
else
	/bin/cat <<EOF >> "$file"

#Creating nginx config for Vhost $PROJECT
server {
 listen 80;
root $PATH/$PROJECT/public_html/;
 index index.php index.html index.htm;
server_name $PROJECT;
location / {
 try_files \$uri \$uri/ /index.php;
 }
location ~ \.php$ {

 proxy_set_header X-Real-IP \$remote_addr;
 proxy_set_header X-Forwarded-For \$remote_addr;
 proxy_set_header Host \$host;
 proxy_pass http://127.0.0.1:8080;

}

location ~ /\.ht {
 deny all;
 }
}
EOF
fi
	echo -e "\nRestarting WebServices Nginx,Mysql and Apache"
	/etc/init.d/httpd restart
	/etc/init.d/mysqld restart
	/etc/init.d/nginx restart
	/usr/bin/mysql_secure_installation
	echo "Configuration completed."
	echo "use 'WebServices restart' to restart Nginx,Mysql and Apache"
elif [ $choice == "N" ]
then
	preConfig
fi
}


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


main(){
	writeConfig
}
main
