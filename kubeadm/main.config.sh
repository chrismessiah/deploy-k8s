# ************************ CLOUD PROVIDER CONFIG *******************************

CLOUD_PROVIDER="DIGITAL_OCEAN"
# CLOUD_PROVIDER="HETZNER_CLOUD"

# ****************************** SCRIPT CONFIG *********************************

# --------- Kubernetes ---------

NODES=2

K8_VERSION="1.14"
K8_VERSION_LONG="1.14.2"

# K8_VERSION="1.13"
# K8_VERSION_LONG="1.13.0"

# --------- Admission Controllers ---------

# USE_POD_SEC_POLICY="true"

# --------- Container Runtime ---------

CONTAINER_RUNTIME="DOCKER"

# CRI-O is not working as intented. The cluster gets created but keep
# Calico SDN fails witht CrashLoopBackOff and Running 0/1. The IPs seem wrong
# too on some components.

# CONTAINER_RUNTIME="CRI-O"
# CRIO_VERSION="1.13"
# CRIO_VERSION="1.14" # CRI-O v1.14 is not released for Ubuntu yet. Use v1.13 atm.

# --------- Cluster Networking ---------

# NETWORK='CILIUM'
NETWORK='CALICO'
# NETWORK='WEAVE'
# NETWORK='WEAVE_ENC' # WEAVE with encrypted network
# NETWORK='FLANNEL'
# NETWORK='CANAL' # uses FLANNEL overlay with CALICO Network Policies

# --------- Helm ---------

# Comment out to HELM to not install

# HELM='true'

# --------- Istio ---------

# Comment out to ISTIO_PROFILE to not install istio at all, requires helm

# ISTIO_PROFILE="PROD"
# ISTIO_PROFILE="DEMO"
# ISTIO_PROFILE="DEMOAUTH"

# --------- Other ---------

# Allow to skip this atm due to K8 error: https://github.com/kubernetes/kubernetes/issues/68270
# USE_PRIVATE_IPS="FALSE"
# USE_PRIVATE_IPS="TRUE"
