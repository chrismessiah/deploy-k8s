# create a shell instance in a new container (ubuntu)
kubectl run my-ubuntu --namespace default --rm -i --tty --image ubuntu:18.04 -- /bin/bash
kubectl run my-ubuntu2 --namespace default --rm -i --tty --labels="app=hello-client" --image ubuntu:18.04 -- /bin/bash

# create a shell instance in a new container (busybox)
kubectl run my-busybox --namespace default --rm -i --tty --image busybox -- sh

# create a shell instance in an existing container
kubectl exec -it --namespace kube-system POD_ID /bin/bash
