# Setting up a Kubernetes Cluster in DigitalOcean

## Prerequisites

```sh
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
```

## Helpful commands

```sh
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

```
