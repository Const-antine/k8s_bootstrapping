#!/usr/bin/env bash

#Assuming keepalived's been already installed by Ansible using any package manager
#script accepts VIP as first argument and any param as a second if it's master



priority=100
KA_CONFIG=/etc/keepalived/keepalived.conf

#defining net interface used on this instance

NETINT=$(route | grep '^default' | grep -o '[^ ]*$')






#Checking if it's master or slave
#first param - VIP anyway & if it's master, script needs second param ( any word, e.g 'master')

if [ $# -gt 1 ]
then
	priority=$(( $priority + 50 ))
fi

cat << EOF > ${KA_CONFIG}

global_defs {

   notification_email {

  root@webserver-02.example.com

   }

   notification_email_from root@webserver-02.example.com

   smtp_server 127.0.0.1

   smtp_connect_timeout 30

   router_id 51

}

vrrp_instance VI_1 {


    state BACKUP

    interface ${NETINT}

#election 150 - master, 100 - slave
    virtual_router_id 51

    priority ${priority}

    advert_int 1

    authentication {

        auth_type PASS

        auth_pass 7263b74db5b509551fbfd1d40f117360

    }

#the most importart part - virtual ip which is dynamically assigned to different nodes

    virtual_ipaddress {

    $1/24

    }

}
EOF


systemctl restart keepalived 1>/dev/null

#checking if ipv4 binding to non-local IP is enabled
if ! grep -Fxq "net.ipv4.ip_nonlocal_bind = 1" /etc/sysctl.conf
then    
        echo "net.ipv4.ip_nonlocal_bind=1" >> /etc/sysctl.conf
        sysctl -p 1>/dev/null
fi

#waiting until VIP is created and assigned
sleep 40



#checking if everything went well

if [ ${priority} -eq 150 ]
then
	if $(ip a | grep -qe $1)
	then
		echo 'Keepalived is initialized successfully'
		exit 0
	else
		echo -e "$1 VIP has not been initialized"
		exit 1
	fi
else
	exit 0
fi


