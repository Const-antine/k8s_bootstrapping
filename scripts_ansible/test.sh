#!/usr/bin/env bash




VIP=$1

if [ $# -eq 2 ]
then
        echo "No need in HaProxy cuz we have 1 master only"
        exit 0
elif [ $# -ge 3 ]
then

count=2
#creating a custom config

cat << EOF > ./haproxy.cfg


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

echo -e "server k8s-master-${count} $i:6443 check fall 3 rise 2" >> ./haproxy.cfg
done

fi


