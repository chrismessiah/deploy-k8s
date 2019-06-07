provision_servers () {
  # ------------------------- Compute -------------------------

  # Note that Istio Pilot requires an extensive amount of resources as mentioned
  # https://github.com/istio/istio/commit/3530fca7e8799a9ecfb8a8207890620604090a97
  # https://github.com/istio/istio/issues/7459

  # *** Hetzner Cloud ***
  # COMPUTE_SIZE="cx11" # 1vCPU 2GB RAM, Pilot won't start in this size
  COMPUTE_SIZE="cx21" # 2vCPU 4GB RAM

  # ------------------------- SSH keys -------------------------

  # *** Hetzner Cloud ***
  # SSH_KEYS="christian" # private
  # SSH_KEYS="821926"

  # Get all available SSH keys
  SSH_KEYS=`hcloud ssh-key list -o noheader | awk '{print $1}' | tr '\n' ','  | awk '{print substr($1, 1, length($1)-1)}'`

  # ------------------------- Script -------------------------

  echo "Provisioning servers from Hetzner Cloud ..."

  cat <<EOT >> teardown.sh
#!/bin/bash
rm -f ~/.kube/config
hcloud server delete master
EOT

  chmod +x teardown.sh

  hcloud server create \
    --name master \
    --type $COMPUTE_SIZE \
    --location nbg1 \
    --image ubuntu-18.04 \
    --ssh-key $SSH_KEYS

  for (( i = 1; i <= $NODES; i++ )); do
    echo "hcloud server delete node$i" >> teardown.sh;

    NODE_NAME="node$i"
    hcloud server create \
      --name $NODE_NAME \
      --type $COMPUTE_SIZE \
      --location nbg1 \
      --image ubuntu-18.04 \
      --ssh-key $SSH_KEYS
  done

  echo "sleep 3" >> teardown.sh;
  echo "hcloud server list" >> teardown.sh;

  MASTER_PUBLIC_IP=`hcloud server list -o noheader | grep master | awk '{print $4}'`

  cat <<EOT >> hosts.cfg
[masters]
master ansible_host=$MASTER_PUBLIC_IP ansible_user=root
EOT

  echo "" >> hosts.cfg
  echo "[workers]" >> hosts.cfg
  for (( i = 1; i <= $NODES; i++ )); do
    NODE_IP=`hcloud server list -o noheader | grep "node$i" | awk '{print $4}'`
    echo "worker$i ansible_host=$NODE_IP ansible_user=root" >> hosts.cfg
  done
  echo "" >> hosts.cfg

  echo "SSH command to master is:        ssh root@$MASTER_PUBLIC_IP" >> hosts.txt
  for (( i = 1; i <= $NODES; i++ )); do
    NODE_IP=`hcloud server list -o noheader | grep "node$i" | awk '{print $4}'`
    echo "SSH command to node$i is:         ssh root@$NODE_IP" >> hosts.txt
  done

  rm provision.log

  echo "Waiting for VMs to boot up ..."
  sleep 60
}
