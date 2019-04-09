#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# ************************ CONFIG VARS ************************

NODES=2



# NETWORK='FLANNEL'
NETWORK='CALICO'
# NETWORK='CANAL' # uses FLANNEL overlay with CALICO Network Policies



# CRI-O v1.14 is not released for Ubuntu yet. Use v1.13 atm.
K8_VERSION="1.13.5"
CRIO_VERSION="1.13"

# K8_VERSION="1.14.0"
# CRIO_VERSION="1.14"


# Allow to skip this atm due to K8 error: https://github.com/kubernetes/kubernetes/issues/68270
USE_PRIVATE_IPS="FALSE"
# USE_PRIVATE_IPS="TRUE"



# Use "doctl compute ssh-key list" to get this
# DO_KEYS="23696360"
DO_KEYS="24225182,24202611"



# Note that Istio Pilot requires an extensive amount of resources as mentioned
# https://github.com/istio/istio/commit/3530fca7e8799a9ecfb8a8207890620604090a97
# https://github.com/istio/istio/issues/7459

# DO_COMPUTE_SIZE="s-2vcpu-2gb" # Pilot won't start in this size
DO_COMPUTE_SIZE="s-2vcpu-4gb"
# DO_COMPUTE_SIZE="s-4vcpu-8gb"

# ************************ SCRIPT ************************

rm provision-servers.log
rm ansible/hosts.cfg

NODE_STRING="" && for (( i = 1; i <= $NODES; i++ )); do NODE_STRING="$NODE_STRING node$i"; done
sed -i "" "s/^doctl compute droplet delete -f node.*/doctl compute droplet delete -f ${NODE_STRING}/" teardown.sh

doctl compute droplet create master $NODE_STRING \
  --ssh-keys $DO_KEYS \
  --region lon1 \
  --image ubuntu-18-04-x64 \
  --size $DO_COMPUTE_SIZE  \
  --format ID,Name,PublicIPv4,PrivateIPv4,Status \
  --enable-private-networking \
  --wait >> provision-servers.log

MASTER_PUBLIC_IP=`cat provision-servers.log | grep master | awk '{print $3}'`
MASTER_PRIVATE_IP=`cat provision-servers.log | grep master | awk '{print $4}'`

cat <<EOT >> ansible/hosts.cfg
[masters]
master ansible_host=$MASTER_PUBLIC_IP ansible_user=root
EOT

echo "" >> ansible/hosts.cfg
echo "[workers]" >> ansible/hosts.cfg
for (( i = 1; i <= $NODES; i++ )); do
  NODE_IP=`cat provision-servers.log | grep "node$i" | awk '{print $3}'`
  echo "worker$i ansible_host=$NODE_IP ansible_user=root" >> ansible/hosts.cfg
done
echo "" >> ansible/hosts.cfg

if [ "$NETWORK" == "CALICO" ]; then CIDR="192.168.0.0/16";
elif [ "$NETWORK" == "FLANNEL" ] || [ "$NETWORK" == "CANAL" ]; then CIDR="10.244.0.0/16";
fi

cat <<EOT >> ansible/hosts.cfg
[all:vars]
ansible_python_interpreter=/usr/bin/python3
master_public_ip=$MASTER_PUBLIC_IP
master_private_ip=$MASTER_PRIVATE_IP
k8_version=$K8_VERSION
crio_version=$CRIO_VERSION
cidr=$CIDR
network=$NETWORK
use_private_ips=$USE_PRIVATE_IPS
EOT

sleep 10

echo "
SSH command to master is:       ssh root@$MASTER_PUBLIC_IP"
for (( i = 1; i <= $NODES; i++ )); do
  NODE_IP=`cat provision-servers.log | grep "node$i" | awk '{print $3}'`
  echo "SSH command to node$i is:         ssh root@$NODE_IP"
done
echo ""
