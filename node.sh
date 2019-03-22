#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# ************* vars *************
TOKEN=b8982b.68123f577c6a71d3
PRIVATE_MASTER_IP=10.131.35.146

# ************* init *************
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

curl https://get.docker.com/ >> install-docker.sh
chmod +x install-docker.sh
./install-docker.sh

apt-get update
apt-get install -y kubelet kubeadm kubectl kubernetes-cni

# ************* node-specific *************
kubeadm join --token $TOKEN $PRIVATE_MASTER_IP:6443 --discovery-token-unsafe-skip-ca-verification

# ************* bonus stuff specific *************
apt install -y python
