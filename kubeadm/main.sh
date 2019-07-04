#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

rm -f teardown.sh
rm -f hosts.txt
rm -f ansible_hosts.cfg

source main.config.sh
source shell-scripts/create_kubeadm_config.sh
source shell-scripts/create_ansible_config.sh
source shell-scripts/helpers.sh

if [ "$CLOUD_PROVIDER" == "DIGITAL_OCEAN" ]; then source shell-scripts/cloud-providers/digital-ocean.sh;
elif [ "$CLOUD_PROVIDER" == "HETZNER_CLOUD" ]; then source shell-scripts/cloud-providers/hetzner-cloud.sh;
fi

provision_servers

KUBEADM_TOKEN=`echo -e "import random,string\ni = string.digits + string.ascii_lowercase\no = ''.join(random.choice(i) for x in range(6))\no += '.'\no += ''.join(random.choice(i) for x in range(16))\nprint o" | python`

create_ansible_config
create_kubeadm_config

ansible-playbook playbooks/main.yaml -i ansible_hosts.cfg

if [ $? -eq 0 ]; then
    MESSAGE="Cluster setup complete"
else
    MESSAGE="Cluster setup failed"
fi

iz_complete
