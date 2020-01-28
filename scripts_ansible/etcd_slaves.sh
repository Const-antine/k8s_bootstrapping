#!/usr/bin/env bash


unarch() {
	tar xfz $1 -C /root
}

unarch /home/$1.tar.gz
mv /root/pki /etc/kubernetes/



kubeadm init phase etcd local --config=/root/kubeadmcfg.yaml




