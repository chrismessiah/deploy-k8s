#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# ************************ CONFIG VARS ************************

NODES=2

# NETWORK='FLANNEL'
NETWORK='CALICO'
# NETWORK='CANAL' # uses FLANNEL overlay with CALICO Network Policies

K8_VERSION="1.13.5"
CRIO_VERSION="1.13"

# K8_VERSION="1.14.0"
# CRIO_VERSION="1.14"

# Use "doctl compute ssh-key list" to get this
# DO_KEYS="23696360"
DO_KEYS="24225182,24202611"


# ************************ SCRIPT ************************

rm provision-servers.log
rm ansible/ansible.conf

NODE_STRING="" && for (( i = 1; i <= $NODES; i++ )); do NODE_STRING="$NODE_STRING node$i"; done
sed -i "" "s/^doctl compute droplet delete -f node.*/doctl compute droplet delete -f ${NODE_STRING}/" teardown.sh

doctl compute droplet create master $NODE_STRING \
  --ssh-keys $DO_KEYS \
  --region lon1 \
  --image ubuntu-18-04-x64 \
  --size s-2vcpu-2gb  \
  --format ID,Name,PublicIPv4,PrivateIPv4,Status \
  --enable-private-networking \
  --wait >> provision-servers.log

MASTER_PUBLIC_IP=`cat provision-servers.log | grep master | awk '{print $3}'`
MASTER_PRIVATE_IP=`cat provision-servers.log | grep master | awk '{print $4}'`

cat <<EOT >> ansible/ansible.conf
[masters]
master ansible_host=$MASTER_PUBLIC_IP ansible_user=root
EOT

echo "" >> ansible/ansible.conf
echo "[workers]" >> ansible/ansible.conf
for (( i = 1; i <= $NODES; i++ )); do
  NODE_IP=`cat provision-servers.log | grep "node$i" | awk '{print $3}'`
  echo "worker$i ansible_host=$NODE_IP ansible_user=root" >> ansible/ansible.conf
done
echo "" >> ansible/ansible.conf

if [ "$NETWORK" == "CALICO" ]; then CIDR="192.168.0.0/16";
elif [ "$NETWORK" == "FLANNEL" ] || [ "$NETWORK" == "CANAL" ]; then CIDR="10.244.0.0/16";
fi

cat <<EOT >> ansible/ansible.conf
[all:vars]
ansible_python_interpreter=/usr/bin/python3
master_public_ip=$MASTER_PUBLIC_IP
master_private_ip=$MASTER_PRIVATE_IP
k8_version=$K8_VERSION
crio_version=$CRIO_VERSION
cidr=$CIDR
network=$NETWORK
EOT

sleep 10

echo "
SSH command to master is:       ssh root@$MASTER_PUBLIC_IP"
for (( i = 1; i <= $NODES; i++ )); do
  NODE_IP=`cat provision-servers.log | grep "node$i" | awk '{print $3}'`
  echo "SSH command to node$i is:         ssh root@$NODE_IP"
done
echo ""
