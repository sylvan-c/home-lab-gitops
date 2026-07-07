#!/usr/bin/env bash
# bootstrap.sh

# Exit immediately if a command exits with a non-zero status,
# Treat unset variables as an error, and catch errors in pipelines.
set -euo pipefail

echo "===================================================="
echo " Starting K3s Bootstrapping: MetalLB & ArgoCD       "
echo "===================================================="

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

if ! command -v helm &> /dev/null; then
  echo "--> Helm not found. Installing via official script..."
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get_helm.sh
  ./get_helm.sh --no-sudo # Installs to /usr/local/bin
  rm get_helm.sh
fi

# 1. Add and Update Helm Repositories
echo "--> Adding Helm repositories..."
helm repo add metallb https://metallb.github.io/metallb
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# 2. Install MetalLB
echo "--> Installing MetalLB via Helm..."
helm upgrade --install metallb metallb/metallb \
  --namespace metallb-system \
  --create-namespace \
  --wait

# 3. Wait for MetalLB Webhook Controller Readiness
echo "--> Waiting for MetalLB validation webhook to be fully ready..."
kubectl rollout status deployment metallb-controller -n metallb-system --timeout=120s
sleep 5

# 4. Apply your Custom MetalLB Layer 2 Pool Configurations
echo "--> Configuring MetalLB Address Pools and L2 Advertisements..."
kubectl apply -f "https://raw.githubusercontent.com/sylvan-c/home-lab-gitops/main/apps/metallb/templates/metallb-ipconfig.yaml"

# 5. Install Initial ArgoCD Instance
echo "--> Installing ArgoCD via Helm..."
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --wait

# 6. Apply root application
kubectl apply -f "https://raw.githubusercontent.com/sylvan-c/home-lab-gitops/main/bootstrap/argocd-root.yaml"

echo "===================================================="
echo " Initial Bootstrap Complete!                        "
echo "===================================================="