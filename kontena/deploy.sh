
# DO_SSH_KEY="24225182" # private
DO_SSH_KEY="24202611"
doctl compute droplet create do-host01 \
  --ssh-keys $DO_SSH_KEY \
  --region fra1 \
  --image ubuntu-18-04-x64 \
  --size s-1vcpu-2gb  \
  --wait

PUBLIC_IP_HOST_1=$(doctl compute droplet get $(doctl compute droplet list | grep "do-host01" | cut -d' ' -f1) --format PublicIPv4 --no-header)

# HC_SSH_KEY="christian" # private
HC_SSH_KEY="821926"
hcloud server create \
  --name hc-host01 \
  --type cx11 \
  --location nbg1 \
  --image ubuntu-18.04 \
  --ssh-key $HC_SSH_KEY

PUBLIC_IP_HOST_2=$(hcloud server list -o columns=ipv4 -o noheader)

echo "
  Please update cluster.yml with the following IPv4

  Digital Ocean Host 1:     $PUBLIC_IP_HOST_1
  Hetzner Cloud Host 1:     $PUBLIC_IP_HOST_2
"

chpharos auto
pharos up -f

pharos kubeconfig  -n pharos-cluster > ~/.kube/config
