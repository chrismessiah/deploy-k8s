# create a shell instance in a new container
kubectl run my-ubuntu --namespace default --rm -i --tty --image ubuntu:18.04 -- /bin/bash
kubectl run my-busybox --namespace default --rm -i --tty --image busybox -- sh

# create a shell instance in an existing container
kubectl exec -it --namespace kube-system POD_ID /bin/bash
