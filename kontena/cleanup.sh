rm -f ~/.kube/config
doctl compute droplet delete -f do-host01
hcloud server delete hc-host01

doctl compute droplet list
hcloud server list
