create_kubeadm_config () {
  rm -f kubeadm-init.yml
  rm -f kubeadm-join.yml

  create_init_config
  echo "---" >> kubeadm-init.yml
  create_cluster_config
}

create_init_config () {
  YML=`cat kubeadm-base-config/init-config.yml`

  echo $MAIN_MASTER

  YML=`echo "$YML" | yq -y ".localAPIEndpoint.advertiseAddress = \"$MAIN_MASTER\""`
  YML=`echo "$YML" | yq -y ".bootstrapTokens = [{\"token\": \"$KUBEADM_TOKEN\",\"description\": \"default kubeadm bootstrap token\"}]"`

  echo "$YML" >> kubeadm-init.yml
}

create_cluster_config() {
  YML=`cat kubeadm-base-config/cluster-config.yml`

  if (( $MASTERS > 1 )); then
    CPE=$LB_IP
  else
    CPE=$MAIN_MASTER
  fi

  YML=`echo "$YML" | yq -y ".controlPlaneEndpoint = \"$CPE:6443\""`
  YML=`echo "$YML" | yq -y ".kubernetesVersion = \"v$K8_VERSION_LONG\""`

  if [ "$NETWORK" == "CALICO" ]; then CIRD="192.168.0.0/16";
  elif [ "$NETWORK" == "FLANNEL" ] || [ "$NETWORK" == "CANAL" ]; then CIRD="10.244.0.0/16";
  elif [ "$NETWORK" == "CILIUM" ] || [ "$NETWORK" == "WEAVE" ]; then echo "Default CIRD mode selected";
  fi

  if [ ! -z "$CIRD" ]; then YML=`echo "$YML" | yq -y '.networking = {}' | yq -y ".networking.podSubnet = \"$CIRD\""`;
  else YML=`echo "$YML" | yq -y 'del(.networking)'`;
  fi

  if [ ! -z "$ADMISSION_CONTROLLERS" ]; then YML=`echo "$YML" | yq -y '.apiServer = {}' | yq -y '.apiServer.extraArgs = {}' | yq -y ".apiServer.extraArgs.enable-admission-plugins = \"$ADMISSION_CONTROLLERS\""`;
  else YML=`echo "$YML" | yq -y 'del(.apiServer)'`;
  fi

  echo "$YML" >> kubeadm-init.yml
}
