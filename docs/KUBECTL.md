# Kubectl CheetSheet

## Useful commands

```sh
kubectl get no
kubectl get nodes

kubectl get pods
kubectl get pods --all-namespaces
kubectl get pods -o wide

kubectl get svc
kubectl get cs # componentstatuses
kubectl cluster-info
kubectl logs POD_NAME

kubectl create -f FILE.yaml
kubectl create namespace NAMESPACE

kubectl proxy # open tunnel from local machine to master, allows access to dashboard http://localhost:8001/ui/

kubectl exec -it PODNAME /bin/bash # access bash inside a pod

kubectl edit deployment/DEPLOYMENT
kubectl rollout status deployment/DEPLOYMENT

kubectl label node NODE LABEL=VALUE # add label to node
kubectl label node NODE LABEL- # remove label from node

# force reschedule
kubectl drain NODE
kubectl cordon NODE
kubectl uncordon NODE

# push to new namespace
kubectl config current-context
kubectl config view -o json | jq .contexts[] # get contexts in local config, use this below
kubectl config set-context dev --namespace=new-namespace --cluster=kubernetes --user=kubernetes-admin
kubectl config use-context dev
kubectl config delete-context dev

kubectl taint nodes NODE KEY=VALUE:NoExecute # add
kubectl taint nodes NODE KEY:NoExecute- # remove
```

## Authorization, secrets and tokens

```sh
# prepare for http requests

SECRET=$(kubectl get sa admin-user -o json --namespace=kube-system | jq -r .secrets[].name)
TOKEN=$(kubectl get secret $SECRET -o json --namespace=kube-system | jq -r '.data["token"]' | base64 -D)
kubectl get secret $SECRET -o json --namespace=kube-system | jq -r '.data["ca.crt"]' | base64 -D > ca.crt

APISERVER_URL=$(kubectl config view | grep server | cut -f 2- -d ":" | tr -d " ")
curl -s --header "Authorization: Bearer $TOKEN" --cacert ./ca.crt $APISERVER_URL/api
curl -s --header "Authorization: Bearer $TOKEN" --cacert ./ca.crt $APISERVER_URL/api/v1/pods
curl -s --header "Authorization: Bearer $TOKEN" --cacert ./ca.crt $APISERVER_URL/api/v1/namespaces/default/pods
curl -s --header "Authorization: Bearer $TOKEN" --cacert ./ca.crt $APISERVER_URL/api/v1/namespaces/default/pods | jq -r ".items[] | {podStatus: .status.phase, podName: .metadata.name, podIP: .status.podIP, nodeName: .spec.nodeName, hostIP: .status.hostIP}"
```
