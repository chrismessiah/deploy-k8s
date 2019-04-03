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
