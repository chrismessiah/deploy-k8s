provision_servers () {
  cat <<EOT >> teardown.sh
#!/bin/bash
rm -f ~/.kube/config
hcloud server delete master
hcloud server list
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

  MASTER_PUBLIC_IP=`hcloud server list -o noheader | grep master | awk '{print $4}'`

  cat <<EOT >> ansible/hosts.cfg
[masters]
master ansible_host=$MASTER_PUBLIC_IP ansible_user=root
EOT

  echo "" >> ansible/hosts.cfg
  echo "[workers]" >> ansible/hosts.cfg
  for (( i = 1; i <= $NODES; i++ )); do
    NODE_IP=`hcloud server list -o noheader | grep "node$i" | awk '{print $4}'`
    echo "worker$i ansible_host=$NODE_IP ansible_user=root" >> ansible/hosts.cfg
  done
  echo "" >> ansible/hosts.cfg

  echo "SSH command to master is:        ssh root@$MASTER_PUBLIC_IP" >> hosts.txt
  for (( i = 1; i <= $NODES; i++ )); do
    NODE_IP=`hcloud server list -o noheader | grep "node$i" | awk '{print $4}'`
    echo "SSH command to node$i is:         ssh root@$NODE_IP" >> hosts.txt
  done

  rm provision.log
}
