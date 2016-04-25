#!/bin/bash

detect_os ()
{
  if [[ ( -z "${os}" ) && ( -z "${dist}" ) ]]; then
    if [ -e /etc/os-release ]; then
      . /etc/os-release
      dist=`echo ${VERSION_ID} | awk -F '.' '{ print $1 }'`
      os=${ID}

    elif [ `which lsb_release 2>/dev/null` ]; then
      # get major version (e.g. '5' or '6')
      dist=`lsb_release -r | cut -f2 | awk -F '.' '{ print $1 }'`

      # get os (e.g. 'centos', 'redhatenterpriseserver', etc)
      os=`lsb_release -i | cut -f2 | awk '{ print tolower($1) }'`

    elif [ -e /etc/oracle-release ]; then
      dist=`cut -f5 --delimiter=' ' /etc/oracle-release | awk -F '.' '{ print $1 }'`
      os='ol'

    elif [ -e /etc/fedora-release ]; then
      dist=`cut -f3 --delimiter=' ' /etc/fedora-release`
      os='fedora'

    elif [ -e /etc/redhat-release ]; then
      os_hint=`cat /etc/redhat-release  | awk '{ print tolower($1) }'`
      if [ "${os_hint}" = "centos" ]; then
        dist=`cat /etc/redhat-release | awk '{ print $3 }' | awk -F '.' '{ print $1 }'`
        os='centos'
	echo "This is centos"
      elif [ "${os_hint}" = "scientific" ]; then
        dist=`cat /etc/redhat-release | awk '{ print $4 }' | awk -F '.' '{ print $1 }'`
        os='scientific'
      else
        dist=`cat /etc/redhat-release  | awk '{ print tolower($7) }' | cut -f1 --delimiter='.'`
        os='redhatenterpriseserver'
      fi

    else
      aws=`grep -q Amazon /etc/issue`
      if [ "$?" = "0" ]; then
        dist='6'
        os='aws'
      else
        unknown_os
      fi
    fi
  fi

  if [[ ( -z "${os}" ) || ( -z "${dist}" ) || ( "${os}" = "opensuse" ) ]]; then
    unknown_os
  fi

  # remove whitespace from OS and dist name
  os="${os// /}"
  dist="${dist// /}"

  echo "Detected operating system as ${os}/${dist}."
  #rpm -Uvh 
}

createWebServices()
{

file="/usr/local/bin/WebServices"
cd ~
OUTPUT=""
OUTPUT=`find -name ".bashrc"`

if grep -q "export PATH=$PATH:/usr/local/bin" "${OUTPUT}"
then
  echo "Not writing"
else
  echo "Writing"
  echo "export PATH=$PATH:/usr/local/bin" >> "${OUTPUT}"
fi
 
if [ -f "$file" ]
then
  echo "$file found."
else
  echo "$file not found. Creating file."
cat > /usr/local/bin/WebServices.sh << EOF1
#!/bin/bash
service httpd "\$1"
service nginx "\$1"
EOF1
install /usr/local/bin/WebServices.sh /usr/local/bin/WebServices
fi
sudo rm -rf /usr/local/bin/WebServices.sh
}

main()
{
	createWebServices
	detect_os
	epel_url="http://dl.fedoraproject.org/pub/epel/${os}/x86_64/epel-release-6-8.noarch.rpm"
	#yum update
	#yum install -y nginx nano apacheyum install httpd mod_ssl php php-pear php-devel

	#sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
	#service iptables save

	#sudo /sbin/chkconfig httpd on
	#sudo /sbin/chkconfig nginx on

	#sh WebServices.sh start

  echo -n "Enter some text > "
  read text
  echo "You entered: $text"

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


}
main