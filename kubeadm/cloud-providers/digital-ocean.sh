provision_servers () {
  # ------------------------- Compute -------------------------

  # Note that Istio Pilot requires an extensive amount of resources as mentioned
  # https://github.com/istio/istio/commit/3530fca7e8799a9ecfb8a8207890620604090a97
  # https://github.com/istio/istio/issues/7459

  # *** Digital Ocean ***
  COMPUTE_SIZE="s-2vcpu-2gb" # Pilot won't start in this size
  # COMPUTE_SIZE="s-2vcpu-4gb"
  # COMPUTE_SIZE="s-4vcpu-8gb"

  # ------------------------- SSH keys -------------------------

  # *** Digital Ocean ***
  # Use "doctl compute ssh-key list" to get this
  # SSH_KEYS="23696360"
  # SSH_KEYS="24225182,24202611"

  # Get all available SSH keys
  SSH_KEYS=`doctl compute ssh-key list --no-header | awk '{print $1}' | tr '\n' ','  | awk '{print substr($1, 1, length($1)-1)}'`

  # ------------------------- Script -------------------------

  echo "Provisioning servers from Digital Ocean ..."


  NODE_STRING="" && for (( i = 1; i <= $NODES; i++ )); do NODE_STRING="$NODE_STRING node$i"; done

  cat <<EOT >> teardown.sh
#!/bin/bash
rm -f ~/.kube/config
doctl compute droplet delete -f master ${NODE_STRING}
sleep 3
doctl compute droplet list
EOT

  chmod +x teardown.sh

  doctl compute droplet create master $NODE_STRING \
    --ssh-keys $SSH_KEYS \
    --region lon1 \
    --image ubuntu-18-04-x64 \
    --size $COMPUTE_SIZE  \
    --format ID,Name,PublicIPv4,PrivateIPv4,Status \
    --enable-private-networking \
    --wait >> provision.log

  MASTER_PUBLIC_IP=`cat provision.log | grep master | awk '{print $3}'`
  MASTER_PRIVATE_IP=`cat provision.log | grep master | awk '{print $4}'`

  cat <<EOT >> hosts.cfg
[masters]
master ansible_host=$MASTER_PUBLIC_IP ansible_user=root
EOT

  echo "" >> hosts.cfg
  echo "[workers]" >> hosts.cfg
  for (( i = 1; i <= $NODES; i++ )); do
    NODE_IP=`cat provision.log | grep "node$i" | awk '{print $3}'`
    echo "worker$i ansible_host=$NODE_IP ansible_user=root" >> hosts.cfg
  done
  echo "" >> hosts.cfg

  echo "SSH command to master is:        ssh root@$MASTER_PUBLIC_IP" >> hosts.txt
  for (( i = 1; i <= $NODES; i++ )); do
    NODE_IP=`cat provision.log | grep "node$i" | awk '{print $3}'`
    echo "SSH command to node$i is:         ssh root@$NODE_IP" >> hosts.txt
  done

  rm provision.log

  echo "Waiting for VMs to boot up ..."
  sleep 30
}
