#!/usr/bin/env bash

source vars.txt

copirator() {
  echo -e "${green}Started copying the files. Using $USER user and $1 target host${NC}"
  sleep 3
  scp $2 $USER@$1:$3
}



checker() {
  
  echo "Checking if k8s initialization's been completed successfully..."
  
  VAR=$( ssh "$USER@$MASTER1 kubectl --kubeconfig /etc/kubernetes/admin.conf get pod -n kube-system -w | tail -n +2 | grep -vc Running" )

  if [[ $VAR  -ne 0 ]];
  then 
	  echo -e "${red}The master hasn't been initialized:(${NC}"
	  ssh $USER@$MASTER1 "kubectl --kubeconfig /etc/kubernetes/admin.conf get pod -n kube-system -w"
  else
	  echo -e "${green}The master has been initialized successfully${NC}"
  exit 1
  else:

  fi
}



