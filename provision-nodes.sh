#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

NODES=2

# Use "doctl compute ssh-key list" to get this
# DO_KEYS="23696360"
DO_KEYS="24225182,24202611"

rm provision.log
rm ansible-hosts

NODE_STRING="" && for (( i = 1; i <= $NODES; i++ )); do NODE_STRING="$NODE_STRING node$i"; done
sed -i "" "s/^doctl compute droplet delete -f node.*/doctl compute droplet delete -f ${NODE_STRING}/" teardown.sh

doctl compute droplet create master $NODE_STRING \
  --ssh-keys $DO_KEYS \
  --region lon1 \
  --image ubuntu-18-04-x64 \
  --size s-2vcpu-2gb  \
  --format ID,Name,PublicIPv4,PrivateIPv4,Status \
  --enable-private-networking \
  --wait >> provision.log

echo "[masters]" >> ansible-hosts

MASTER_IP=`cat provision.log | grep master | awk '{print $3}'`
echo "master ansible_host=$MASTER_IP ansible_user=root" >> ansible-hosts

echo "" >> ansible-hosts

echo "[workers]" >> ansible-hosts

for (( i = 1; i <= $NODES; i++ )); do
  NODE_IP=`cat provision.log | grep "node$i" | awk '{print $3}'`
  echo "worker$i ansible_host=$NODE_IP ansible_user=root" >> ansible-hosts
done
