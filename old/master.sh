#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# ************* vars *************
CONTAINER_RUNTIME=DOCKER
KUBERNETES_VERSION=1.13.5
TOKEN=b8982b.68123f577c6a71d3
NETWORK=CALICO
# ************* init *************

PUBLIC_MASTER_IP=`ifconfig eth0 | grep 'inet ' | cut -d: -f2 | awk '{print $2}'`
PRIVATE_MASTER_IP=`ifconfig eth1 | grep 'inet ' | cut -d: -f2 | awk '{print $2}'`

# ************ Install container runtime ************
if [ "$CONTAINER_RUNTIME" == "DOCKER" ]
then
  CRI_SOCKET_FULL=""
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
  apt-get update
  apt-get install -y docker-ce=18.06.2~ce~3-0~ubuntu

  systemctl daemon-reload
  systemctl restart docker

elif [ "$CONTAINER_RUNTIME" == "CRI-O" ]
then
  CRI_SOCKET="/var/run/crio/crio.sock"
  CRI_SOCKET_FULL="--cri-socket=$CRI_SOCKET"
  modprobe overlay
  modprobe br_netfilter
  cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

  sysctl --system
  add-apt-repository -y ppa:projectatomic/ppa
  CRIO_VERSION=`echo $KUBERNETES_VERSION | cut -f1-2 -d"."`
  apt-get install -y cri-o-$CRIO_VERSION
  systemctl start crio
fi

# ************ Install K8 ************
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update

KUBELET_VERSION=`apt-cache madison kubelet | grep $KUBERNETES_VERSION | head -n 1 | cut -d: -f1 | awk '{print $3}'`
KUBEADM_VERSION=`apt-cache madison kubeadm | grep $KUBERNETES_VERSION | head -n 1 | cut -d: -f1 | awk '{print $3}'`
KUBECTL_VERSION=`apt-cache madison kubectl | grep $KUBERNETES_VERSION | head -n 1 | cut -d: -f1 | awk '{print $3}'`
apt-get install -y kubelet=$KUBELET_VERSION kubeadm=$KUBEADM_VERSION kubectl=$KUBECTL_VERSION kubernetes-cni
apt-mark hold kubelet kubeadm kubectl

# ************* master specific *************
sed -i "s~ExecStart=/usr/bin/kubelet.*~& --node-ip=$PRIVATE_MASTER_IP~" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

systemctl daemon-reload
systemctl restart kubelet

if [ "$NETWORK" == "CALICO" ]
then
  kubeadm init --token $TOKEN --apiserver-advertise-address $PUBLIC_MASTER_IP --pod-network-cidr=192.168.0.0/16 $CRI_SOCKET_FULL --kubernetes-version=$KUBERNETES_VERSION >> kubeadm.log
elif [ "$NETWORK" == "FLANNEL" ]
then
  kubeadm init --token $TOKEN --apiserver-advertise-address $PUBLIC_MASTER_IP --pod-network-cidr=10.244.0.0/16  $CRI_SOCKET_FULL --kubernetes-version=$KUBERNETES_VERSION >> kubeadm.log
elif [ "$NETWORK" == "CANAL" ]
then
  kubeadm init --token $TOKEN --apiserver-advertise-address $PUBLIC_MASTER_IP --pod-network-cidr=10.244.0.0/16  $CRI_SOCKET_FULL --kubernetes-version=$KUBERNETES_VERSION >> kubeadm.log
fi

mkdir -p $HOME/.kube && sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && sudo chown $(id -u):$(id -g) $HOME/.kube/config

if [ "$NETWORK" == "CALICO" ]
then
  IP_AUTODETECTION_METHOD=interface=eth1
  IP6_AUTODETECTION_METHOD=interface=eth1
  kubectl apply -f https://docs.projectcalico.org/v3.6/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml
elif [ "$NETWORK" == "FLANNEL" ]
then
  kubectl create -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml --namespace=kube-system
elif [ "$NETWORK" == "CANAL" ]
then
  kubectl apply -f https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/canal/rbac.yaml
  kubectl apply -f https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/canal/canal.yaml
fi
