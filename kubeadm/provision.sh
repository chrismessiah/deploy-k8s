#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# ************************ CONFIG VARS ************************

NODES=2



# NETWORK='FLANNEL'
NETWORK='CALICO'
# NETWORK='CANAL' # uses FLANNEL overlay with CALICO Network Policies

# CRI-O is not working as intented. The cluster gets created but keep
# Calico SDN fails witht CrashLoopBackOff and Running 0/1. The IPs seem wrong
# too on some components.
CONTAINER_RUNTIME="DOCKER"
# CONTAINER_RUNTIME="CRI-O"

# CRI-O v1.14 is not released for Ubuntu yet. Use v1.13 atm.
K8_VERSION="1.13.5"
CRIO_VERSION="1.13"

# K8_VERSION="1.14.0"
# CRIO_VERSION="1.14"

# ISTIO_PROFILE="PROD"
ISTIO_PROFILE="DEMO"
# ISTIO_PROFILE="DEMOAUTH"


# Allow to skip this atm due to K8 error: https://github.com/kubernetes/kubernetes/issues/68270
USE_PRIVATE_IPS="FALSE"
# USE_PRIVATE_IPS="TRUE"

# ************************ CLOUD PROVIDER CONFIG ************************

# Note that Istio Pilot requires an extensive amount of resources as mentioned
# https://github.com/istio/istio/commit/3530fca7e8799a9ecfb8a8207890620604090a97
# https://github.com/istio/istio/issues/7459

# CLOUD_PROVIDER="DIGITAL_OCEAN"
CLOUD_PROVIDER="HETZNER_CLOUD"

# ------------------------- Compute -------------------------

# *** Digital Ocean ***
# COMPUTE_SIZE="s-2vcpu-2gb" # Pilot won't start in this size
# COMPUTE_SIZE="s-2vcpu-4gb"
# COMPUTE_SIZE="s-4vcpu-8gb"

# *** Hetzner Cloud ***
COMPUTE_SIZE="cx11" # 1vCPU 2GB RAM, Pilot won't start in this size
# COMPUTE_SIZE="cx21" # 2vCPU 4GB RAM

# ------------------------- SSH keys -------------------------

# *** Digital Ocean ***
# Use "doctl compute ssh-key list" to get this
# SSH_KEYS="23696360"
# SSH_KEYS="24225182,24202611"

# *** Hetzner Cloud ***
# SSH_KEYS="christian" # private
SSH_KEYS="821926"

# ************************ SCRIPT ************************

> teardown.sh
rm provision.log
rm ansible/hosts.cfg

if [ "$CLOUD_PROVIDER" == "DIGITAL_OCEAN" ]; then source cloud-providers/digital-ocean.sh;
elif [ "$CLOUD_PROVIDER" == "HETZNER_CLOUD" ]; then source cloud-providers/hetzner-cloud.sh;
fi

provision_servers

if [ "$NETWORK" == "CALICO" ]; then CIDR="192.168.0.0/16";
elif [ "$NETWORK" == "FLANNEL" ] || [ "$NETWORK" == "CANAL" ]; then CIDR="10.244.0.0/16";
fi

cat <<EOT >> ansible/hosts.cfg
[all:vars]
ansible_python_interpreter=/usr/bin/python3
master_public_ip=$MASTER_PUBLIC_IP
master_private_ip=$MASTER_PRIVATE_IP
k8_version=$K8_VERSION
crio_version=$CRIO_VERSION
container_runtime=$CONTAINER_RUNTIME
cidr=$CIDR
network=$NETWORK
use_private_ips=$USE_PRIVATE_IPS
istio_profile=$ISTIO_PROFILE
EOT
