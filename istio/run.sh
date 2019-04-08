
# download istio
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=1.1.2 sh -

################################################################################
# See https://istio.io/docs/setup/kubernetes/install/helm/ for more info on the
# installation procedure
################################################################################

kubectl create namespace istio-system

# Use helm client to install Istio CRDs
cd istio
cd istio-1.1.1
helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -

# Verify installation, should return 53 or 58
watch -n 2 "kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l"

# choose a configuration profile described in
# https://istio.io/docs/setup/kubernetes/install/helm/
# https://istio.io/docs/setup/kubernetes/additional-setup/config-profiles/
#
# Default profile (for production)
helm template install/kubernetes/helm/istio --name istio --namespace istio-system | kubectl apply -f -
#
# Demo profile
helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-demo.yaml | kubectl apply -f -

# force istio-proxy sidecar injection in the default namespace
kubectl label namespace default istio-injection=enabled

# revert to remove label
# kubectl label namespace default istio-injection-

# wait til ready
watch -n 2 "kubectl get pods --all-namespaces"



# Other stuff
kubectl get svc --all-namespaces | grep istio-ingressgateway
ISTIO_LB_CLUSTER_IP=`kubectl get svc --all-namespaces | grep istio-ingressgateway | awk '{print $4}'`
