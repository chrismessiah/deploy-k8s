#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

NODES=2
NODE_REQUIREMENT=2 # in case of hiccups, should be equal or lower than $NODES

# Use "doctl compute ssh-key list" to get this
# DO_KEYS="23696360"
DO_KEYS="24225182,24202611"

# NETWORK='FLANNEL'
NETWORK='CALICO'
# NETWORK='CANAL' # uses FLANNEL overlay with CALICO Network Policies

# CONTAINER_RUNTIME="DOCKER"
CONTAINER_RUNTIME="CRI-O"

# Must be MAJOR.MINOR.PATCH
KUBERNETES_VERSION="1.13.5"

# Hard-code token, generate this for production K8
TOKEN="b8982b.68123f577c6a71d3"

# ************* replacements *************
sed -i "" "s/^TOKEN=.*/TOKEN=${TOKEN}/" master.sh
sed -i "" "s/^TOKEN=.*/TOKEN=${TOKEN}/" node.sh

sed -i "" "s/^NETWORK=.*/NETWORK=${NETWORK}/" master.sh

sed -i "" "s/^CONTAINER_RUNTIME=.*/CONTAINER_RUNTIME=${CONTAINER_RUNTIME}/" master.sh
sed -i "" "s/^CONTAINER_RUNTIME=.*/CONTAINER_RUNTIME=${CONTAINER_RUNTIME}/" node.sh

sed -i "" "s/^KUBERNETES_VERSION=.*/KUBERNETES_VERSION=${KUBERNETES_VERSION}/" master.sh
sed -i "" "s/^KUBERNETES_VERSION=.*/KUBERNETES_VERSION=${KUBERNETES_VERSION}/" node.sh

NODE_STRING="node1" && for (( i = 2; i <= $NODES; i++ )); do NODE_STRING="$NODE_STRING node$i"; done
sed -i "" "s/^doctl compute droplet delete -f node.*/doctl compute droplet delete -f ${NODE_STRING}/" teardown.sh

# ************* start *************
echo "-> creating master VM and initalizing with master.sh"
doctl compute droplet create master --ssh-keys $DO_KEYS --region lon1 --image ubuntu-18-04-x64 --size s-2vcpu-2gb  --format ID,Name,PublicIPv4,PrivateIPv4,Status --enable-private-networking --user-data-file master.sh --wait

echo "-> get master's private IP and replace in node.sh"
PUBLIC_MASTER_IP=$(doctl compute droplet get $(doctl compute droplet list | grep "master" | cut -d' ' -f1) --format PublicIPv4 --no-header)
PRIVATE_MASTER_IP=$(doctl compute droplet get $(doctl compute droplet list | grep "master" | cut -d' ' -f1) --format PrivateIPv4 --no-header)
sed -i "" "s/^PRIVATE_MASTER_IP=.*/PRIVATE_MASTER_IP=${PRIVATE_MASTER_IP}/" node.sh

echo "-> creating worker node VMs and initalizing with node.sh"
doctl compute droplet create $NODE_STRING --ssh-keys $DO_KEYS --region lon1 --image ubuntu-18-04-x64 --size s-2vcpu-2gb --format ID,Name,PublicIPv4,PrivateIPv4,Status --enable-private-networking --user-data-file node.sh --wait

# ***************************** WAIT UNITL COMPLETE *****************************
SLEEP_SECS=60
echo "-> waiting $SLEEP_SECS seconds for master to finish setup ..."
sleep $SLEEP_SECS

mkdir ~/.kube

while true
do
	scp -o StrictHostKeyChecking=no root@$PUBLIC_MASTER_IP:/etc/kubernetes/admin.conf ~/.kube/config
	if [ "$?" -eq "0" ]; then
		echo "Master setup complete!" && break
	fi
	sleep 2
done

echo "WAITING: Nodes are setting up ..."
while true
do
	NUM=$(kubectl get nodes | grep "node" |  grep -c " Ready ")
	if [ "$NUM" -ge "$NODE_REQUIREMENT" ]; then
		echo "Node setup complete!"
  		break
	fi
	sleep 2
done

# ***************************** COMPLETE *****************************
echo "*************** Cluster setup complete ***************"

KERNEL=$(uname)
if [ "$KERNEL" == "Darwin" ]; then
	say "Cluster setup complete" -v Samantha
	osascript -e 'display notification "Cluster setup complete"'
fi

watch -n 2 kubectl get pods --all-namespaces
