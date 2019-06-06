#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

rm -f teardown.sh
rm -f hosts.txt
rm -f provision.log
rm -f hosts.cfg

source config.sh

if [ "$CLOUD_PROVIDER" == "DIGITAL_OCEAN" ]; then source cloud-providers/digital-ocean.sh;
elif [ "$CLOUD_PROVIDER" == "HETZNER_CLOUD" ]; then source cloud-providers/hetzner-cloud.sh;
fi

provision_servers

cat <<EOT >> hosts.cfg
[all:vars]
ansible_python_interpreter=/usr/bin/python3
master_public_ip=$MASTER_PUBLIC_IP
master_private_ip=$MASTER_PRIVATE_IP
k8_version=$K8_VERSION
k8_version_long=$K8_VERSION_LONG
container_runtime=$CONTAINER_RUNTIME
network=$NETWORK
use_private_ips=$USE_PRIVATE_IPS
EOT

[ ! -z "$ISTIO_PROFILE" ] && echo "istio_profile=$ISTIO_PROFILE" >> hosts.cfg
[ ! -z "$CRIO_VERSION" ] && echo "crio_version=$CRIO_VERSION" >> hosts.cfg

if [ "$NETWORK" == "CALICO" ]; then echo "cidr=192.168.0.0/16" >> hosts.cfg;
elif [ "$NETWORK" == "FLANNEL" ] || [ "$NETWORK" == "CANAL" ]; then echo "cidr=10.244.0.0/16" >> hosts.cfg;
elif [ "$NETWORK" == "CILIUM" ]; then echo "No CIDR for Cilium";
fi

ansible-playbook playbooks/main.yaml -i hosts.cfg

KERNEL=$(uname)
if [ "$KERNEL" == "Darwin" ]; then
	say "Cluster setup complete" -v Samantha
	osascript -e 'display notification "Cluster setup complete"'
fi

watch -n 2 kubectl get pods --all-namespaces -o wide
