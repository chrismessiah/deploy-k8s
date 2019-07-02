
# shorthand verison, eg. 1.13 or 1.14
K8_VERSION="$(echo $K8_VERSION_LONG | cut -d'.' -f1 -f2)"

create_ansible_config () {
  cat <<EOT >> ansible_hosts.cfg
[all:vars]
ansible_python_interpreter=/usr/bin/python3
master_public_ip=$MASTER_PUBLIC_IP
k8_version=$K8_VERSION
k8_version_long=$K8_VERSION_LONG
container_runtime=$CONTAINER_RUNTIME
network=$NETWORK
nodes=$NODES
EOT

  [ ! -z "$HELM" ] && echo "helm=$HELM" >> ansible_hosts.cfg
  [ ! -z "$ISTIO_PROFILE" ] && echo "istio_profile=$ISTIO_PROFILE" >> ansible_hosts.cfg
  [ ! -z "$CRIO_VERSION" ] && echo "crio_version=$CRIO_VERSION" >> ansible_hosts.cfg

}
