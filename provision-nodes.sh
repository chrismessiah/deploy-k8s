#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

NODES=2

# Use "doctl compute ssh-key list" to get this
# DO_KEYS="23696360"
DO_KEYS="24225182,24202611"

rm provision-nodes.log
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
  --wait >> provision-nodes.log

MASTER_PUBLIC_IP=`cat provision-nodes.log | grep master | awk '{print $3}'`
MASTER_PRIVATE_IP=`cat provision-nodes.log | grep master | awk '{print $4}'`

cat <<EOT >> ansible/ansible.conf
[masters]
master ansible_host=$MASTER_PUBLIC_IP ansible_user=root
EOT

echo "" >> ansible/ansible.conf
echo "[workers]" >> ansible/ansible.conf
for (( i = 1; i <= $NODES; i++ )); do
  NODE_IP=`cat provision-nodes.log | grep "node$i" | awk '{print $3}'`
  echo "worker$i ansible_host=$NODE_IP ansible_user=root" >> ansible/ansible.conf
done
echo "" >> ansible/ansible.conf

cat <<EOT >> ansible/ansible.conf
[all:vars]
ansible_python_interpreter=/usr/bin/python3
master_public_ip=$MASTER_PUBLIC_IP
master_private_ip=$MASTER_PRIVATE_IP
k8_version=1.13.5
crio_version=1.13
cidr=192.168.0.0/16
network=Calico
EOT

echo "\nSSH command to master is: ssh root@$MASTER_PUBLIC_IP \n"

sleep 10
