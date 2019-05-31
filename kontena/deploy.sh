chpharos auto

# DO_SSH_KEY="24225182" # private
DO_SSH_KEY="24202611"
doctl compute droplet create do-host01 \
  --ssh-keys $DO_SSH_KEY \
  --region fra1 \
  --image ubuntu-18-04-x64 \
  --size s-1vcpu-2gb  \
  --wait

# HC_SSH_KEY="christian" # private
HC_SSH_KEY="821926"
hcloud server create \
  --name hc-host01 \
  --type cx11 \
  --location nbg1 \
  --image ubuntu-18.04 \
  --ssh-key $HC_SSH_KEY

# ***** update cluster.yml with IPv4 ******

pharos up

pharos kubeconfig  -n pharos-cluster > ~/.kube/config
