# create a shell instance in a new container (ubuntu)
kubectl run my-ubuntu -n default --rm -i --tty --image ubuntu:18.04 -- /bin/bash
kubectl run my-ubuntu2 -n default --rm -i --tty --labels="app=hello-client" --image ubuntu:18.04 -- /bin/bash

# create a shell instance in a new container (busybox)
kubectl run my-busybox -n default --rm -i --tty --image busybox -- sh
kubectl run my-busybox2 -n default --rm -i --tty --labels="app=hello-client" --image busybox -- sh

# create a shell instance in an existing container
kubectl exec -it -n kube-system POD_ID /bin/bash
