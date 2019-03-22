#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

DO_KEYS="23696360,24225182" # Use "doctl compute ssh-key list" to get this
NODES=2
NODE_REQUIREMENT=2 # in case of hiccups, should be equal or lower than $NODES

# NETWORK='FLANNEL'
NETWORK='CALICO'
# NETWORK='CANAL' # uses FLANNEL overlay with CALICO Network Policies

# Hard-code token, generate this for production K8
TOKEN="b8982b.68123f577c6a71d3"

# ************* replacements *************
sed -i "" "s/^TOKEN=.*/TOKEN=${TOKEN}/" master.sh
sed -i "" "s/^TOKEN=.*/TOKEN=${TOKEN}/" node.sh
sed -i "" "s/^NETWORK=.*/NETWORK=${NETWORK}/" master.sh
NODE_STRING="node1" && for (( i = 2; i <= $NODES; i++ )); do NODE_STRING="$NODE_STRING node$i"; done
sed -i "" "s/^doctl compute droplet delete -f node.*/doctl compute droplet delete -f ${NODE_STRING}/" teardown.sh

# ************* start *************
echo "-> creating master VM and initalizing with master.sh"
doctl compute droplet create master --ssh-keys $DO_KEYS --region lon1 --image ubuntu-18-04-x64 --size s-2vcpu-2gb  --format ID,Name,PublicIPv4,PrivateIPv4,Status --enable-private-networking --user-data-file master.sh --wait

echo "-> get master's IP and replace in node.sh"
PUBLIC_MASTER_IP=$(doctl compute droplet get $(doctl compute droplet list | grep "master" | cut -d' ' -f1) --format PublicIPv4 --no-header)
PRIVATE_MASTER_IP=$(doctl compute droplet get $(doctl compute droplet list | grep "master" | cut -d' ' -f1) --format PrivateIPv4 --no-header)
sed -i "" "s/^PRIVATE_MASTER_IP=.*/PRIVATE_MASTER_IP=${PRIVATE_MASTER_IP}/" master.sh
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
		echo "Master setup complete!"
  		break
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

# ***************************** DEPLOY *****************************
# kubectl run hello-web --image=chrismessiah/hello-nodejs --port 3000
# kubectl scale deployment hello-web --replicas=2

kubectl run hello-web --image=chrismessiah/hello-nodejs --port 3000 --labels='app=hello-web' --replicas=3
kubectl create -f ./demos/baseline/deployment.yaml -f ./demos/baseline/service.yaml
kubectl create -f ./user.yaml -f ./rbac.yaml

watch -n 2 kubectl get pods -o wide

exit 1

	# get ip of nodes
	doctl compute droplet list

	# confirm setup (run on master)
	kubectl get no # nodes

	# additional commands to play with to check the cluster (run on master)
	kubectl get pods
	kubectl get svc # services
	kubectl get cs # componentstatuses
	kubectl cluster-info
	kubectl logs my-pod

	kubectl get nodes
	kubectl create -f foo.yaml # deploy an app
	kubectl proxy # open tunnel from local machine to master, allows access to dashboard http://localhost:8001/ui/

	kubectl exec -it PODNAME /bin/bash # access bash inside a pod

	# kubectl run -it busybox --image=busybox # busybox is an image with multiple unix tools

	# create a pod which sends requests to another pod on another node
	# Flannel: 10.244.1.42
	# Calico: 192.168.104.1
	kubectl create -f ./demos/baseline/request.yaml

	kubectl get pods -o wide
	kubectl get pods --all-namespaces

	kubectl edit deployment/DEPLOYMENT
	kubectl rollout status deployment/DEPLOYMENT

	kubectl label node NODE LABEL=VALUE # add label to node
	kubectl label node NODE LABEL- # remove label from node

	# force reschedule
	kubectl drain NODE
	kubectl cordon NODE
	kubectl uncordon NODE

	# push to new namespace
	kubectl create namespace NAMESPACE
	kubectl config current-context
	kubectl config view -o json | jq .contexts[] # get contexts in local config, use this below
	kubectl config set-context dev --namespace=new-namespace --cluster=kubernetes --user=kubernetes-admin
	kubectl config use-context dev
	kubectl config delete-context dev

	kubectl scale deployment DEPLOYMENT --replicas=4 # scale up deployment

	kubectl taint nodes NODE KEY=VALUE:NoExecute # add
	kubectl taint nodes NODE KEY:NoExecute- # remove

	kubectl apply -f https://docs.projectcalico.org/master/getting-started/kubernetes/installation/hosted/calicoctl.yaml
	kubectl apply -f https://docs.projectcalico.org/master/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calicoctl.yaml
	kubectl exec -ti -n kube-system calicoctl -- /calicoctl get profiles -o json

	# prepare for http requests

	SECRET=$(kubectl get sa admin-user -o json --namespace=kube-system | jq -r .secrets[].name)
	TOKEN=$(kubectl get secret $SECRET -o json --namespace=kube-system | jq -r '.data["token"]' | base64 -D)
	kubectl get secret $SECRET -o json --namespace=kube-system | jq -r '.data["ca.crt"]' | base64 -D > ca.crt

	APISERVER_URL=$(kubectl config view | grep server | cut -f 2- -d ":" | tr -d " ")
	curl -s --header "Authorization: Bearer $TOKEN" --cacert ./ca.crt $APISERVER_URL/api
	curl -s --header "Authorization: Bearer $TOKEN" --cacert ./ca.crt $APISERVER_URL/api/v1/pods
	curl -s --header "Authorization: Bearer $TOKEN" --cacert ./ca.crt $APISERVER_URL/api/v1/namespaces/default/pods
	curl -s --header "Authorization: Bearer $TOKEN" --cacert ./ca.crt $APISERVER_URL/api/v1/namespaces/default/pods | jq -r ".items[] | {podStatus: .status.phase, podName: .metadata.name, podIP: .status.podIP, nodeName: .spec.nodeName, hostIP: .status.hostIP}"

	kubectl run my-shell --rm -i --tty --image ubuntu -- bash
	apt-get update && apt-get install -y curl

	# use tshark to filter away own ip and only UDP (due to VXLAN)
	apt install -y tshark iftop

	# capture filters
	tshark -f 'not host 77.218.255.217'
	tshark -f '(not host 206.189.28.133) and (not host 77.218.255.222)'
	tshark -f '(not host 206.189.28.133) and (not host 77.218.255.221) and (not host 213.86.144.41) and (not host 206.189.12.73)'
	tshark -f 'udp'
	tshark -f 'port 290'
	tshark -f 'not tcp'

	# display filters
	tshark -Y http

	# interface
	tshark -i flannel.1

	# total
	tshark -i flannel.1 -Y http
	tshark -i cali041b8026940 -Y http
	tshark -i calif48e9637a36 -Y http

	curl http://10.244.2.2:3000
