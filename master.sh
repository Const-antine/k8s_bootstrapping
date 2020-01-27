#!/usr/bin/env bash

source vars.txt
source functions.sh


echo -e "${green}Checking the files on source${NC}"

if [ -f ${ETCD_SSL_DIR}/ca.crt ] && [ -f ${MAIN_SSL_DIR}/apiserver-etcd-client.crt ] && [ -f ${MAIN_SSL_DIR}/apiserver-etcd-client.key ];
then
  echo -e "${green}The necessary files are present${NC}"
else
  echo -e "${red}No certificates to to pass, exiting${NC}"
  exit 1
fi

echo -e "${green}Copying the files to target server${NC}"


ssh "$USER"@$MASTER1 mkdir -p ${ETCD_SSL_DIR}

copirator $MASTER1 ${ETCD_SSL_DIR}/ca.crt ${ETCD_SSL_DIR}
copirator $MASTER1 ${MAIN_SSL_DIR}/apiserver-etcd-client.crt ${MAIN_SSL_DIR}
copirator $MASTER1 ${MAIN_SSL_DIR}/apiserver-etcd-client.key ${MAIN_SSL_DIR}



echo -e "${green}Creating the kubeadm init conf${NC}"

ssh $USER@$MASTER1 cat << EOF > /$USER/kubeadm-config.yaml

apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
networking:
        podSubnet: "${POD_SUBNET}"
kubernetesVersion: stable
apiServer:
  certSANs:
  - "$VIP_IP"
  - "$MASTER1"
  - "$MASTER2"
  - "$ETCD0"
  - "$ETCD1"
  - "$ETCD2"
controlPlaneEndpoint: "$VIP_IP:6443"
etcd:
    external:
        endpoints:
        - https://$ETCD0:2379
        - https://$ETCD1:2379
        - https://$ETCD2:2379
        caFile: ${ETCD_SSL_DIR}/ca.crt
        certFile: ${MAIN_SSL_DIR}/apiserver-etcd-client.crt
        keyFile: ${MAIN_SSL_DIR}/apiserver-etcd-client.key
EOF




copirator $MASTER1 /root/kubeadm-config.yaml /root





echo -e "${green}Started Master node initialization${NC}"

#ssh $USER@$MASTER1 kubeadm init --config /$USER/kubeadm-config.yaml | tee -a /$USER/temp_output.txt
#ASSIGNER=$( ssh $USER@$MASTER1 "cat /$USER/temp_output.txt | grep 'discovery-token-ca-cert-hash' | awk -F 'kubeadm'  '{ print FS $1}' |awk -F 'control-plane' '{print $1 FS }'")


#echo -e $ASSIGNER
echo


#ssh $USER@$MASTER1 kubectl --kubeconfig /etc/kubernetes/admin.conf apply -f "https://cloud.weave.works/k8s/net?k8s-version=$( kubectl --kubeconfig /etc/kubernetes/admin.conf version | base64 | tr -d '\n')"



#echo -e "${green}Waiting until all the kube-system pods are up and running...${NC}"

#while [ $secs -gt 0 ]; do
#   echo -ne "$secs\033[0K\r"
#   sleep 1
#   : $((secs--))
#done


#checker

echo -e "${green}If you see this message, all goes well :)${NC}"

