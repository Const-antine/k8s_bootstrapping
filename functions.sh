#!/usr/bin/env bash

source vars.txt

copirator() {
  echo -e "${green}Started copying the files. Using $USER user and $1 target host${NC}"
  sleep 3
  scp $2 $USER@$1:$3
}


checker() {

echo -e "${green}Checking if k8s initialization's been completed successfully...${NC}"

VAR=$( ssh -t $USER@$MASTER1 << EOF
kubectl --kubeconfig ${KUBE_CONF} get pod -n kube-system -w | tail -n +2 | grep -vc Running
EOF
 )


if [[ $VAR  -ne 0 ]];
  then 
	  echo -e "${red}The master hasn't been initialized:(${NC}"
	  exit 1
  else
	  echo -e "${green}All kube-system pods are up and runnin on ${MASTER1}"
  fi

}

