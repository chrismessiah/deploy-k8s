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
```

## Cilium Metrics

### Cilium-specific Metrics

```sh
cilium metrics list | grep datapath_errors_total
```

## Layer 3/4 Metrics


```sh
cilium metrics list | grep drop_count_total
cilium metrics list | grep forward_count_total

cilium metrics list | grep drop_bytes_total
cilium metrics list | grep forward_bytes_total
```

## Layer 7 Metrics

Unlike layer 3 and layer 4 policies, violation of layer 7 rules does not result in packet drops. Instead, if possible, an application protocol specific access denied message is crafted and returned, e.g. an HTTP 403 access denied is sent back for HTTP requests which violate the policy, or a DNS REFUSED response for DNS requests.

```sh
cilium metrics list | grep policy_l7_denied_total
cilium metrics list | grep policy_l7_parse_errors_total

```

## Other

```sh
cilium bpf metrics list

cilium endpoint list # list all local endpoints
cilium endpoint log ENDPOINT


cilium policy trace -s <app.from> -d <app.to> --dport 80 # Check policy enforcement between two labels on port 80:
cilium policy trace --src-identity SRC_ID --dst-identity DEST_ID # Check policy enforcement between two identities
cilium policy trace --src-k8s-pod NAMESPACE:SRC_POD --dst-k8s-pod NAMESPACE:DST_POD # Check policy enforcement between two pods:

# cilium monitor only shows LOCAL events !!!
cilium monitor
cilium monitor --related-to=ENDPOINT_OR_ID # Filter for only the events related to endpoint
cilium monitor -t L7 # Filter for only events on layer 7
cilium monitor --type drop # Show notifications only for dropped packet events
```
