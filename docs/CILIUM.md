# Cilium

There are 2 commands that are relevant

* `cilium` - The CLI for interacting with local Cilium Agent
* `cilium-agent` - Used to start and configure the Cilium Agent

```sh
# find the cilium pod
CILIUM_MASTER_POD=`kubectl get pods -n kube-system -o wide | grep master | grep cilium | awk '{print $1}'`

# enter cilium pod
kubectl exec -it --namespace kube-system $CILIUM_MASTER_POD /bin/bash

# check if Cilium Agent is running
cilium status

cilium monitor
cilium metrics list

cilium metrics list | grep drop_count_total
cilium metrics list | grep drop_bytes_total
```
