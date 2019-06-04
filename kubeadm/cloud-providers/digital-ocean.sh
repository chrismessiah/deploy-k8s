provision_servers () {
  NODE_STRING="" && for (( i = 1; i <= $NODES; i++ )); do NODE_STRING="$NODE_STRING node$i"; done

  cat <<EOT >> teardown.sh
#!/bin/bash
rm -f ~/.kube/config
doctl compute droplet delete -f master ${NODE_STRING}
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

  cat <<EOT >> ansible/hosts.cfg
[masters]
master ansible_host=$MASTER_PUBLIC_IP ansible_user=root
EOT

  echo "" >> ansible/hosts.cfg
  echo "[workers]" >> ansible/hosts.cfg
  for (( i = 1; i <= $NODES; i++ )); do
    NODE_IP=`cat provision.log | grep "node$i" | awk '{print $3}'`
    echo "worker$i ansible_host=$NODE_IP ansible_user=root" >> ansible/hosts.cfg
  done
  echo "" >> ansible/hosts.cfg

  echo "SSH command to master is:        ssh root@$MASTER_PUBLIC_IP" >> hosts.txt
  for (( i = 1; i <= $NODES; i++ )); do
    NODE_IP=`cat provision.log | grep "node$i" | awk '{print $3}'`
    echo "SSH command to node$i is:         ssh root@$NODE_IP" >> hosts.txt
  done

  rm provision.log
}
