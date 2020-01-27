#!/usr/bin/env bash

source vars.txt
source functions.sh


checker() {
VAR=$( ssh -t $USER@$MASTER1 << EOF
kubectl --kubeconfig /etc/kubernetes/admin.conf get pod -n kube-system -w | tail -n +2 | grep -vc Running
EOF
 )


if [[ $VAR  -ne 0 ]];
  then 
	  echo -e "${red}The master hasn't been initialized:(${NC}"
  else
	  echo "All is perfect"
  fi

}




