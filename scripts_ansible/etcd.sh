#!/usr/bin/env bash


#Assuming kubelet/kubectl/kubeadm have been already installed by Ansible using any package manager
#Script should be run on ETCD master


#TODO get rid of hardcoding of the number of instances in ETCD cluster

#count=0
#for i in ${@}; do
#HOST=$i
#count=$(( $count + 1 ))
#done




KUBE_CONF=/usr/lib/systemd/system/kubelet.service.d/20-etcd-service-manager.conf
HOST0=$1
HOST1=$2
HOST2=$3
ETCDHOSTS=(${HOST0} ${HOST1} ${HOST2})
NAMES=("infra0" "infra1" "infra2")

generator(){

  kubeadm init phase certs etcd-server --config=/tmp/$1/kubeadmcfg.yaml
  kubeadm init phase certs etcd-peer --config=/tmp/$1/kubeadmcfg.yaml
  kubeadm init phase certs etcd-healthcheck-client --config=/tmp/$1/kubeadmcfg.yaml
  kubeadm init phase certs apiserver-etcd-client --config=/tmp/$1/kubeadmcfg.yaml

  cp -Rf /etc/kubernetes/pki /tmp/$1/
  if [ -d /tmp/$1/ ]
  then
    if [ $1 != ${HOST0} ]
    then
      find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete
      find /tmp/$1 -name ca.key -type f -delete
      sleep 3
    fi
  else
    exit 1
  fi
}

archiever() {	
	tar -cfz /home/$2.tar.gz $1
}




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

mkdir -p /tmp/${HOST0}/ /tmp/${HOST1}/ /tmp/${HOST2}/

for i in "${!ETCDHOSTS[@]}"; do
    HOST=${ETCDHOSTS[$i]}
    NAME=${NAMES[$i]}
    cat << EOF > /tmp/${HOST}/kubeadmcfg.yaml
    apiVersion: "kubeadm.k8s.io/v1beta2"
    kind: ClusterConfiguration
    etcd:
      local:
          serverCertSANs:
          - "${HOST}"
          peerCertSANs:
          - "${HOST}"
          extraArgs:
              initial-cluster: ${NAMES[0]}=https://${ETCDHOSTS[0]}:2380,${NAMES[1]}=https://${ETCDHOSTS[1]}:2380,${NAMES[2]}=https://${ETCDHOSTS[2]}:2380
              initial-cluster-state: new
              name: ${NAME}
              listen-peer-urls: https://${HOST}:2380
              listen-client-urls: https://${HOST}:2379
              advertise-client-urls: https://${HOST}:2379
              initial-advertise-peer-urls: https://${HOST}:2380
EOF
      done

#local CA init
kubeadm init phase certs etcd-ca

#generating all the necessary certs and copying them to /tmp
generator ${HOST2} && generator ${HOST1}  && generator ${HOST0}


archiever /tmp/${HOST1} ${HOST1}
archiever /tmp/${HOST2} ${HOST2}


kubeadm init phase etcd local --config=/tmp/${HOST0}/kubeadmcfg.yaml

#Script will generate two archives which should be copied to the other nodes of ETCD 




