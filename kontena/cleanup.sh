# cleanup
doctl compute droplet delete -f node01
doctl compute droplet list

hcloud server delete node02
hcloud server list

doctl compute droplet delete -f do-host01
hcloud server delete hc-host01
