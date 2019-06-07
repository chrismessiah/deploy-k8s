# Weave Net

```sh
# Get pod name
WEAVE_MASTER_POD=`kubectl get pods -n kube-system -o wide | grep weave-net | grep master | awk '{print $1}'`

# Enter container
kubectl exec -it -n kube-system $WEAVE_MASTER_POD -c weave -- sh

# check status
./weave --local status
```
