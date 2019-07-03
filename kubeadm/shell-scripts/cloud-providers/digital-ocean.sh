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
  MASTER_STRING="" && for (( i = 1; i <= $MASTERS; i++ )); do MASTER_STRING="$MASTER_STRING master$i"; done

  cat <<EOT >> teardown.sh
#!/bin/bash
rm -f ~/.kube/config
doctl compute droplet delete -f ${MASTER_STRING} ${NODE_STRING}
EOT

if (( $MASTERS > 1 )); then
  echo "doctl compute droplet delete -f k8-lb" >> teardown.sh
fi
echo "sleep 3 && doctl compute droplet list" >> teardown.sh

  chmod +x teardown.sh

  doctl compute droplet create $MASTER_STRING $NODE_STRING \
    --ssh-keys $SSH_KEYS \
    --region lon1 \
    --image ubuntu-18-04-x64 \
    --size $COMPUTE_SIZE  \
    --format ID,Name,PublicIPv4,PrivateIPv4,Status \
    --wait >> creating_servers.log

  echo "[masters]" >> ansible_hosts.cfg
  for (( i = 1; i <= $MASTERS; i++ )); do
    MASTER_NAME="master$i"
    MASTER_PUBLIC_IP=`cat creating_servers.log | grep $MASTER_NAME | awk '{print $3}'`
    echo "$MASTER_NAME ansible_host=$MASTER_PUBLIC_IP ansible_user=root" >> ansible_hosts.cfg
    echo "SSH command to $MASTER_NAME is:        ssh root@$MASTER_PUBLIC_IP" >> hosts.txt
    declare MASTER_PUBLIC_IP_$i=$MASTER_PUBLIC_IP
  done

  echo "" >> hosts.txt
  echo "" >> ansible_hosts.cfg

  cat <<EOT >> ansible_hosts.cfg
[master_main]
master1 ansible_host=$MASTER_PUBLIC_IP_1 ansible_user=root

EOT

  if (( $MASTERS > 1 )); then
    echo "[masters_fallback]" >> ansible_hosts.cfg
    for (( i = 2; i <= $MASTERS; i++ )); do
      MASTER_NAME="master$i"
      IP_VAR_NAME=MASTER_PUBLIC_IP_$i
      echo "$MASTER_NAME ansible_host=${!IP_VAR_NAME} ansible_user=root" >> ansible_hosts.cfg
    done
    echo "" >> ansible_hosts.cfg
  fi

  echo "[workers]" >> ansible_hosts.cfg
  for (( i = 1; i <= $NODES; i++ )); do
    NODE_NAME="node$i"
    NODE_IP=`cat creating_servers.log | grep $NODE_NAME | awk '{print $3}'`
    echo "$NODE_NAME ansible_host=$NODE_IP ansible_user=root" >> ansible_hosts.cfg
    echo "SSH command to $NODE_NAME is:         ssh root@$NODE_IP" >> hosts.txt
  done
  echo "" >> ansible_hosts.cfg


  if (( $MASTERS > 1 )); then
    doctl compute droplet create k8-lb \
      --ssh-keys $SSH_KEYS \
      --region lon1 \
      --image ubuntu-18-04-x64 \
      --size $COMPUTE_SIZE  \
      --format ID,Name,PublicIPv4,PrivateIPv4,Status \
      --wait >> creating_servers.log
    LB_IP=`cat creating_servers.log | grep k8-lb | awk '{print $3}'`
    cat <<EOT >> ansible_hosts.cfg
[loadbalancers]
loadbalancer ansible_host=$LB_IP ansible_user=root

EOT
    echo "SSH command to k8-lb is:         ssh root@$LB_IP" >> hosts.txt
  fi

  rm creating_servers.log

  echo "Waiting for VMs to boot up ..."
  sleep 30
}
