#!/usr/bin/env bash

copirator() {
  echo -e "${green}Started copying the files. Using $USER user and $1 target host${NC}"
  sleep 3
  scp $2 $USER@$1:$3
}


checker() {
  VAR=$( ssh $USER@$MASTER1 kubectl --kubeconfig /etc/kubernetes/admin.conf get pod -n kube-system -w | tail -n +2 | grep -vc Running )

  if [[ $VAR  -ne 0 ]];
  then echo -e "${red}The master hasn't been initialized:(${NC}";
  exit 1
  fi
}



echo -e "${green}Checking the files on source${NC}"

if [ -f /etc/kubernetes/pki/etcd/ca.crt ] && [ -f /etc/kubernetes/pki/apiserver-etcd-client.crt ] && [ -f /etc/kubernetes/pki/apiserver-etcd-client.key ];
then
  echo -e "${green}The necessary files are present${NC}"
else
  echo -e "${red}No certificates to to pass, exiting${NC}"
  exit 1
fi

echo -e "${green}Copying the files to target server${NC}"


ssh "$USER"@$MASTER1 mkdir -p /etc/kubernetes/pki/etcd/

copirator $MASTER1 /etc/kubernetes/pki/etcd/ca.crt /etc/kubernetes/pki/etcd/
copirator $MASTER1 /etc/kubernetes/pki/apiserver-etcd-client.crt /etc/kubernetes/pki/
copirator $MASTER1 /etc/kubernetes/pki/apiserver-etcd-client.key /etc/kubernetes/pki/


echo -e "${green}Creating the kubeadm init conf${NC}"

ssh $USER@$MASTER1 cat << EOF > /$USER/kubeadm-config.yaml

apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
networking:
        podSubnet: "192.168.1.0/16"
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
        caFile: /etc/kubernetes/pki/etcd/ca.crt
        certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt
        keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key
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

