#!/usr/bin/env bash


#Assuming kubelet/kubectl/kubeadm have been already installed by Ansible using any package manager


KUBE_CONF=/usr/lib/systemd/system/kubelet.service.d/20-etcd-service-manager.conf

count=0
for i in ${@}; do
HOST=$i

mkdir -p /tmp/${HOST}/

count=$(( $count + 1 ))
done




#Creating Kubelet config with higher priority

cat << EOF > ${KUBE_CONF}

[Service]
ExecStart=
ExecStart=/usr/bin/kubelet --address=127.0.0.1 --pod-manifest-path=/etc/kubernetes/manifests
Restart=always
EOF

#TODO maybe it's better to reload/restart via Ansible notify
systemctl daemon-reload
systemctl restart kubelet





