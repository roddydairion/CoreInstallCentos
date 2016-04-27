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
#cd ~
#OUTPUT=""
#OUTPUT=`find -name ".bashrc"`

#if grep -q "export PATH=$PATH:/usr/local/bin" "${OUTPUT}"
#then
#  echo "Not writing"
#else
#  echo "Writing"
#  echo "export PATH=$PATH:/usr/local/bin" >> "${OUTPUT}"
#fi
 
if [ -f "$file" ]
then
  echo "$file found."
else
  echo "$file not found. Creating file."
cat > /usr/local/bin/WebServices.sh << EOF1
#!/bin/bash
services httpd "\$1"
services nginx "\$1"
services mysqld "\$1"
EOF1
install /usr/local/bin/WebServices.sh /usr/local/bin/WebServices
fi
sudo rm -rf /usr/local/bin/WebServices.sh
}

main()
{
  clear
	createWebServices
	detect_os
	epel_url="http://dl.fedoraproject.org/pub/epel/${os}/x86_64/epel-release-6-8.noarch.rpm"
	yum update
	yum install -y nginx nano apacheyum mysql-server install httpd mod_ssl php php-pear php-devel php-mysql

	sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
  sudo iptables -I INPUT -p tcp --dport 3306 -j ACCEPT

	service iptables save

	sudo /sbin/chkconfig httpd on
	sudo /sbin/chkconfig nginx on
  sudo /sbin/chkconfig mysqld on
  
  DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	./RunConfig.sh
}
main
