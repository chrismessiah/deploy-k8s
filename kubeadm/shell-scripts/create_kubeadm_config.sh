create_kubeadm_config () {
  rm -f kubeadm-init.yml
  rm -f kubeadm-join.yml

  TOKEN=`echo -e "import random,string\ni = string.digits + string.ascii_lowercase\no = ''.join(random.choice(i) for x in range(6))\no += '.'\no += ''.join(random.choice(i) for x in range(16))\nprint o" | python`

  create_init_config
  echo "---" >> kubeadm-init.yml
  create_cluster_config

  create_join_config
  # echo "---" >> kubeadm-join.yml
}

create_cluster_config () {
  YML=`cat kubeadm-base-config/init-config.yml`

  YML=`echo "$YML" | yq -y ".localAPIEndpoint.advertiseAddress = \"$MASTER_PUBLIC_IP\""`
  YML=`echo "$YML" | yq -y ".bootstrapTokens = [{\"token\": \"$TOKEN\",\"description\": \"default kubeadm bootstrap token\"}]"`

  echo "$YML" >> kubeadm-init.yml
}

create_init_config () {
  YML=`cat kubeadm-base-config/cluster-config.yml`

  YML=`echo "$YML" | yq -y ".controlPlaneEndpoint = \"$MASTER_PUBLIC_IP:6443\""`
  YML=`echo "$YML" | yq -y ".kubernetesVersion = \"v$K8_VERSION_LONG\""`

  if [ "$NETWORK" == "CALICO" ]; then CIRD="192.168.0.0/16";
  elif [ "$NETWORK" == "FLANNEL" ] || [ "$NETWORK" == "CANAL" ]; then CIRD="10.244.0.0/16";
  elif [ "$NETWORK" == "CILIUM" ] || [ "$NETWORK" == "WEAVE" ]; then echo "Default CIRD mode selected";
  fi

  if [ ! -z "$CIRD" ]; then YML=`echo "$YML" | yq -y '.networking = {}' | yq -y ".networking.podSubnet = \"$CIRD\""`;
  else YML=`echo "$YML" | yq -y 'del(.networking)'`;
  fi

  echo "$YML" >> kubeadm-init.yml
}

create_join_config () {
  YML=`cat kubeadm-base-config/join-config.yml`

  YML=`echo "$YML" | yq -y ".discovery.bootstrapToken.apiServerEndpoint = \"$MASTER_PUBLIC_IP:6443\""`
  YML=`echo "$YML" | yq -y ".discovery.bootstrapToken.token = \"$TOKEN\""`

  echo "$YML" >> kubeadm-join.yml
}
