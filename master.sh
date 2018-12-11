#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# ************* vars *************
TOKEN=XXXX
NETWORK=XXXX

# ************* init *************
MASTER_IP=`ifconfig eth0 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}'`

apt-get update && apt-get upgrade -y

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

curl https://get.docker.com/ >> install-docker.sh && chmod +x install-docker.sh && ./install-docker.sh

apt-get update -y && apt-get install -y kubelet kubeadm kubectl kubernetes-cni


# ************* master specific *************
if [ "$NETWORK" == "CALICO" ]
then
  kubeadm init --token $TOKEN --apiserver-advertise-address $MASTER_IP --pod-network-cidr=192.168.0.0/16
elif [ "$NETWORK" == "FLANNEL" ]
then
  kubeadm init --token $TOKEN --apiserver-advertise-address $MASTER_IP --pod-network-cidr=10.244.0.0/16
elif [ "$NETWORK" == "CANAL" ]
then
  kubeadm init --token $TOKEN --apiserver-advertise-address $MASTER_IP --pod-network-cidr=10.244.0.0/16
fi


mkdir -p $HOME/.kube && sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && sudo chown $(id -u):$(id -g) $HOME/.kube/config

if [ "$NETWORK" == "CALICO" ]
then
  kubectl apply -f https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml
elif [ "$NETWORK" == "FLANNEL" ]
then
  kubectl create -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml --namespace=kube-system
elif [ "$NETWORK" == "CANAL" ]
then
  kubectl apply -f https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/canal/rbac.yaml
  kubectl apply -f https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/canal/canal.yaml
fi

# ************* bonus stuff specific *************
apt install -y python

# install dashboard to visualize cluster
# kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml --namespace=kube-system
