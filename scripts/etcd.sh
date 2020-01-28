#!/usr/bin/env bash


HOST0=192.168.1.42
HOST1=192.168.1.43
HOST2=192.168.1.44
green='\033[0;32m'
NC='\033[0m'
red='\033[0;31m'
USER=$(whoami)
k8s_version=$(kubeadm version | cut -d, -f3 | grep -i Version | cut -d: -f2 | cut -d\" -f2 |sed 's/v//g')
ETCD_TAG=$(kubeadm config images list --kubernetes-version ${k8s_version})

echo -e "${green}Defined the necessary values:${NC}"



echo $HOST0 
echo $HOST1
echo $HOST2

echo $k8s_version
echo $ETCD_TAG



generator(){
  echo -e "${green}Generating SSls for ${1}${NC}"

  kubeadm init phase certs etcd-server --config=/tmp/$1/kubeadmcfg.yaml
  kubeadm init phase certs etcd-peer --config=/tmp/$1/kubeadmcfg.yaml
  kubeadm init phase certs etcd-healthcheck-client --config=/tmp/$1/kubeadmcfg.yaml
  kubeadm init phase certs apiserver-etcd-client --config=/tmp/$1/kubeadmcfg.yaml

  echo -e "${green}Copying the SSL files to the tmp directory${NC}"
  cp -Rf /etc/kubernetes/pki /tmp/$1/
  if [ -d /tmp/$1/ ]
  then
    echo -e "${green}The files are copied${NC}"



    if [ $1 != ${HOST0} ]
    then
      echo -e "${green}Cleaning up the /etc/kubernetes/pki directory and removing ca.key  in /tmp for $1${NC}"
      find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete
      find /tmp/$1 -name ca.key -type f -delete
      sleep 3
    fi
  else
    echo -e "${green}Dir could not be created${NC}"
    exit 1
  fi
}


copirator() {
  echo -e "${green}Started copying the files. Using $USER user and $1 target host${NC}"
  sleep 3
  ssh $USER@$1 mkdir -p /etc/kubernetes/pki
  scp -r /tmp/$1/pki $USER@$1:/etc/kubernetes/
  scp /tmp/$1/kubeadmcfg.yaml $USER@$1:/root
  val=$(ssh $USER@$1 find /etc/kubernetes/pki | wc -l)
  if [ $val -eq 11 ]
  then
    echo -e "${green}The files were copied to $1 host successfully${NC}"
  fi
}

manifestator() {
  echo -e "${green} Generating the manifests on each node${NC}"
  if [ $1 = ${HOST0} ]
  then
    kubeadm init phase etcd local --config=/tmp/$1/kubeadmcfg.yaml
  else
    ssh $USER@$1 kubeadm init phase etcd local --config=/root/kubeadmcfg.yaml
  fi
}


while true; do
    read -p "Are you sure that the SSH were copied to *all* hosts?" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo -e "${red}Please answer yes or no.${NC}";;
    esac
done


echo
if [ -s "/tmp/${HOST0}/kubeadmcfg.yaml" ] && [ -s "/tmp/${HOST1}/kubeadmcfg.yaml" ] && [ -s "/tmp/${HOST2}/kubeadmcfg.yaml" ]
then
  echo -e "${green}files are already generated, proceeding${NC}"
else
  echo -e "${green}Creating the target directories${NC}"
  mkdir -p /tmp/${HOST0}/ /tmp/${HOST1}/ /tmp/${HOST2}/
  ETCDHOSTS=(${HOST0} ${HOST1} ${HOST2})
  NAMES=("infra0" "infra1" "infra2")


  echo -e "${green}Generating the configs...${NC}"
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

fi




echo -e "${green}Creating CA${NC}"
kubeadm init phase certs etcd-ca

generator ${HOST2} && generator ${HOST1}  && generator ${HOST0}
copirator ${HOST1} && copirator ${HOST2}
manifestator ${HOST0} && manifestator ${HOST1}  && manifestator ${HOST2}

echo -e "${green}The manifests are generated successfully, testing${NC}"

