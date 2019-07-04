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
EOT

  chmod +x teardown.sh

  for (( i = 1; i <= $MASTERS; i++ )); do
    MASTER_NAME="master$i"
    echo "hcloud server delete $MASTER_NAME" >> teardown.sh;

    hcloud server create \
      --name $MASTER_NAME \
      --type $COMPUTE_SIZE \
      --location nbg1 \
      --image ubuntu-18.04 \
      --ssh-key $SSH_KEYS
  done

  for (( i = 1; i <= $NODES; i++ )); do
    NODE_NAME="node$i"
    echo "hcloud server delete $NODE_NAME" >> teardown.sh;

    hcloud server create \
      --name $NODE_NAME \
      --type $COMPUTE_SIZE \
      --location nbg1 \
      --image ubuntu-18.04 \
      --ssh-key $SSH_KEYS
  done

  echo "[masters]" >> ansible_hosts.cfg
  for (( i = 1; i <= $MASTERS; i++ )); do
    MASTER_NAME="master$i"
    MASTER_PUBLIC_IP=`hcloud server list -o noheader | grep $MASTER_NAME | awk '{print $4}'`
    echo "$MASTER_NAME ansible_host=$MASTER_PUBLIC_IP ansible_user=root" >> ansible_hosts.cfg
    echo "SSH command to $MASTER_NAME is:        ssh root@$MASTER_PUBLIC_IP" >> hosts.txt
    declare MASTER_PUBLIC_IP_$i=$MASTER_PUBLIC_IP
  done

  echo "" >> ansible_hosts.cfg

  cat <<EOT >> ansible_hosts.cfg
[master_main]
master1 ansible_host=$MASTER_PUBLIC_IP_1 ansible_user=root

EOT

MAIN_MASTER=$MASTER_PUBLIC_IP_1

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
    NODE_IP=`hcloud server list -o noheader | grep $NODE_NAME | awk '{print $4}'`
    echo "$NODE_NAME ansible_host=$NODE_IP ansible_user=root" >> ansible_hosts.cfg
    echo "SSH command to $NODE_NAME is:         ssh root@$NODE_IP" >> hosts.txt
  done

  if (( $MASTERS > 1 )); then
    hcloud server create \
      --name k8-lb \
      --type $COMPUTE_SIZE \
      --location nbg1 \
      --image ubuntu-18.04 \
      --ssh-key $SSH_KEYS

    LB_IP=`hcloud server list -o noheader | grep k8-lb | awk '{print $4}'`
    echo "hcloud server delete k8-lb" >> teardown.sh;
    cat <<EOT >> ansible_hosts.cfg

[loadbalancers]
loadbalancer ansible_host=$LB_IP ansible_user=root

EOT
    echo "SSH command to k8-lb is:         ssh root@$LB_IP" >> hosts.txt
  fi

  echo "sleep 3" >> teardown.sh;
  echo "hcloud server list" >> teardown.sh;

  echo "Waiting for VMs to boot up ..."
  sleep 60
}
