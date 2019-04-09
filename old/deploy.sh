#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# install Kubernetes dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml
kubectl apply -f k8-dashboard/User.yaml -f k8-dashboard/ClusterRoleBinding.yaml
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')

# run sample app and create a ClusterIP service
kubectl run hello-deployment --image=chrismessiah/hello-world --labels='app=hello-world' --replicas=2 --port 3000

# ISTIO NOTE:
#   Due to bug highlighted in https://github.com/istio/istio/issues/9504#issuecomment-472612138
#   Istio-proxy fails to start when there is a port mismatch. In this case we need to skip the --port parameter!
kubectl run hello-deployment --image=chrismessiah/hello-world --labels='app=hello-world' --replicas=2

# Create service
kubectl expose deployment hello-deployment --port=80 --target-port=3000

# revert
kubectl delete deployment hello-deployment
kubectl delete svc hello-deployment

# Install Istio without Tiller
kubectl create namespace istio-system
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=1.1.1 sh -
cd istio-1.1.1
helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
export PATH=$PWD/bin:$PATH # add istioctl to PATH
cd ..
watch -n 2 "kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l" # should be 53

# OR: Install Istio and Tiller
kubectl apply -f install/kubernetes/helm/helm-service-account.yaml
helm init --service-account tiller
helm install install/kubernetes/helm/istio-init --name istio-init --namespace istio-system
kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l
watch -n 2 "kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l" # should be 53

#
kubectl create -f ./demos/baseline/deployment.yaml -f ./demos/baseline/service.yaml
kubectl create -f ./user.yaml -f ./rbac.yaml

watch -n 2 kubectl get pods -o wide
