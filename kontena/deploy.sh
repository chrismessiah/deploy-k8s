cd provision-kontena-cluster

chpharos auto

doctl compute droplet create do-host01 \
  --ssh-keys 24225182 \
  --region fra1 \
  --image ubuntu-18-04-x64 \
  --size s-1vcpu-2gb  \
  --wait

hcloud server create \
  --name hc-host01 \
  --type cx11 \
  --location nbg1 \
  --image ubuntu-18.04 \
  --ssh-key christian

# ***** update cluster.yml with IPv4 ******

pharos up

pharos kubeconfig  -n pharos-cluster > ~/.kube/config
