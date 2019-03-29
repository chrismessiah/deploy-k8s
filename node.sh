#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# ************* vars *************
CONTAINER_RUNTIME=CRI-O
KUBERNETES_VERSION=1.13
TOKEN=b8982b.68123f577c6a71d3
PRIVATE_MASTER_IP=10.131.106.226

# ************ Install container runtime ************
if [ "$CONTAINER_RUNTIME" == "DOCKER" ]
then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
  apt-get update
  apt-get install -y docker-ce=18.06.2~ce~3-0~ubuntu
  cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

  mkdir -p /etc/systemd/system/docker.service.d

  systemctl daemon-reload
  systemctl restart docker
elif [ "$CONTAINER_RUNTIME" == "CRI-O" ]
then
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


# ************* node-specific *************
kubeadm join --token $TOKEN $PRIVATE_MASTER_IP:6443 --discovery-token-unsafe-skip-ca-verification

# ************* bonus stuff specific *************
apt install -y python
