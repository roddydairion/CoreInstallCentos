#!/bin/bash
listIP=`/sbin/ifconfig | /bin/awk '/inet addr/{print substr($2,6)}'`
select ip in $listIP; do
if [ "$ip" = "exit" ]
then
	exit 0
elif [ -n "$ip" ]
then
	echo $ip
	break
else
	echo "Invalid IP selected! Try again"
fi
done
