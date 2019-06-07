# Weave Net

```sh
# Get pod name
WEAVE_MASTER_POD=`kubectl get pods -n kube-system -o wide | grep weave-net | grep master | awk '{print $1}'`

# Enter container
kubectl exec -it -n kube-system $WEAVE_MASTER_POD /bin/bash

weave status
weave --local status


echo "s3cr3tp4ssw0rd" > /var/lib/weave/weave-passwd
kubectl create secret -n kube-system generic weave-passwd --from-file=/var/lib/weave/weave-passwd
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&password-secret=weave-passwd"

```
