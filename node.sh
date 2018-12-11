#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# ************* vars *************
TOKEN=XXXXX
MASTER_IP=XXXXX

# ************* init *************
apt-get update && apt-get upgrade -y

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update -y && apt-get install -y docker.io kubelet kubeadm kubectl kubernetes-cni

# ************* node-specific *************
kubeadm join --token $TOKEN $MASTER_IP:6443 --discovery-token-unsafe-skip-ca-verification

# ************* bonus stuff specific *************
apt install -y python