#!/usr/bin/env bash


#This script should be run via Ansible on all the ETCD nodes from HA cluster
#The scripts requires parameters ( VIP & IPs of master nodes on backend)
#e.g ./haproxy.sh 193.111.63.252-VIP 193.111.63.249-MASTER1 193.111.63.240MASTER2 193.111.63.235MASTER3 193.111.63.228MASTER4




#defining our Virtual IP which will be created by keepalived later
VIP=$1
HA_CONFIG=/etc/haproxy/haproxy.cfg

#backing up the default config of haproxy
mv ${HA_CONFIG}{,.back}

#defining have many Master instances are on backend
if [ $# -eq 2 ]
then
        echo "No need in HaProxy cuz we only have 1 master on backend"
        exit 0
elif [ $# -ge 3 ]
then

count=2
#creating a custom config

cat << EOF > ${HA_CONFIG}


global
    user haproxy
    group haproxy
defaults
    mode http
    log global
    retries 2
    timeout connect 3000ms
    timeout server 5000ms
    timeout client 5000ms
frontend kubernetes
    bind ${VIP}:6443
    option tcplog
    mode tcp
    default_backend kubernetes-master-nodes
backend kubernetes-master-nodes
    mode tcp
    balance roundrobin
    option tcp-check
server k8s-master-0 $2:6443 check fall 3 rise 2
server k8s-master-1 $3:6443 check fall 3 rise 2
EOF


for i in ${@:4}; do
count=$(( $count + 1 ))

echo -e "server k8s-master-${count} $i:6443 check fall 3 rise 2" >> ${HA_CONFIG}
done

fi

#enabling ipv4 binding to non-local IP 
echo "net.ipv4.ip_nonlocal_bind=1" >> /etc/sysctl.conf
sysctl -p 1>/dev/null

#Most likely, we'll get errors here since Keepalived ain't started & VIP ain't created
systemctl restart haproxy > /dev/null 2>&1






