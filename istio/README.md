# Istio

## Accessing Kiali

```sh
MASTER_IP="209.97.137.230"
KIALI_SVC_IP=`kubectl get svc --all-namespaces | grep kiali | awk '{print $4}'`
ssh -L 8080:$KIALI_SVC_IP:20001 root@$MASTER_IP

curl localhost:8080/kiali/console
# or enter in browser
# username:password is admin:admin

```
