#!/usr/bin/env bash

PATH1='192.168.1.40:/etc/kubernetes/pki/'

PATH2='192.168.1.40:/etc/kubernetes/pki/etcd'

for i in /etc/kubernetes/pki/{ca.key,ca.crt,sa.key,sa.pub,front-proxy-ca.crt,front-proxy-ca.key,apiserver-etcd-client.crt,apiserver-etcd-client.key};
do scp $i ${PATH1}; 
done;

scp /etc/kubernetes/admin.conf 192.168.1.40:/etc/kubernetes
scp /etc/kubernetes/pki/etcd/ca.crt ${PATH2}
