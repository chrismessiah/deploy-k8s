#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

rm -f teardown.sh
rm -f hosts.txt
rm -f ansible_hosts.cfg

source provision_cluster_config.sh

if [ "$CLOUD_PROVIDER" == "DIGITAL_OCEAN" ]; then source cloud-providers/digital-ocean.sh;
elif [ "$CLOUD_PROVIDER" == "HETZNER_CLOUD" ]; then source cloud-providers/hetzner-cloud.sh;
fi

provision_servers

cat <<EOT >> ansible_hosts.cfg
[all:vars]
ansible_python_interpreter=/usr/bin/python3
master_public_ip=$MASTER_PUBLIC_IP
k8_version=$K8_VERSION
k8_version_long=$K8_VERSION_LONG
container_runtime=$CONTAINER_RUNTIME
network=$NETWORK
EOT

[ ! -z "$HELM" ] && echo "helm=$HELM" >> ansible_hosts.cfg
[ ! -z "$ISTIO_PROFILE" ] && echo "istio_profile=$ISTIO_PROFILE" >> ansible_hosts.cfg
[ ! -z "$CRIO_VERSION" ] && echo "crio_version=$CRIO_VERSION" >> ansible_hosts.cfg

# ************************* kubeadm-init.yml ***********************************

rm -f kubeadm-config/kubeadm-init.yml

YML=`cat kubeadm-config/base/init-configuration.yml`

# Update master IP
YML=`echo "$YML" | yq -y ".localAPIEndpoint.advertiseAddress = \"$MASTER_PUBLIC_IP\""`

# update bootstrap token
TOKEN=`echo -e "import random,string\ni = string.digits + string.ascii_lowercase\no = ''.join(random.choice(i) for x in range(6))\no += '.'\no += ''.join(random.choice(i) for x in range(16))\nprint o" | python`
YML=`echo "$YML" | yq -y ".bootstrapTokens = [{\"token\": \"$TOKEN\",\"description\": \"default kubeadm bootstrap token\"}]"`
echo "$YML" >> kubeadm-config/kubeadm-init.yml



echo "---" >> kubeadm-config/kubeadm-init.yml



YML=`cat kubeadm-config/base/cluster-configuration.yml`
YML=`echo "$YML" | yq -y ".kubernetesVersion = \"v$K8_VERSION_LONG\""`

if [ "$NETWORK" == "CALICO" ]; then CIRD="192.168.0.0/16";
elif [ "$NETWORK" == "FLANNEL" ] || [ "$NETWORK" == "CANAL" ]; then CIRD="10.244.0.0/16";
elif [ "$NETWORK" == "CILIUM" ] || [ "$NETWORK" == "WEAVE" ]; then echo "Default CIRD mode selected";
fi

if [ ! -z "$CIRD" ]; && YML=`echo "$YML" | yq -y '.networking = {}' | yq -y ".networking.podSubnet = \"$CIRD\""`

# Insert element
echo "$YML" | yq '. |= .+ {"foo": "bar"}'

# Update a value
echo "$YML" | yq -y '.foo = "bar2"'

# Put in kubeadm-init.conf
$MASTER_PUBLIC_IP

# Put in kubeadm-init.conf

# Put in kubeadm-init.conf and # Put in kubeadm-join.conf
[ ! -z "$USE_PRIVATE_IPS" ] && echo "use_private_ips=$USE_PRIVATE_IPS" >> ansible_hosts.cfg &&\
															 echo "master_private_ip=$MASTER_PRIVATE_IP" >> ansible_hosts.cfg

ansible-playbook playbooks/main.yaml -i ansible_hosts.cfg

KERNEL=$(uname)
if [ "$KERNEL" == "Darwin" ]; then
	say "Cluster setup complete" -v Samantha
	osascript -e 'display notification "Cluster setup complete"'
fi

watch -n 2 kubectl get pods --all-namespaces -o wide
