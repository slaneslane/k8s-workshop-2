#!/usr/bin/env bash
set -euo pipefail

KUBECTL_VERSION="v1.30.0"
ARCH="amd64"
WORKSHOP_USER="k8s"

# Optional proxy configuration. Leave empty if not needed.
HTTP_PROXY_URL="${HTTP_PROXY_URL:-}"
HTTPS_PROXY_URL="${HTTPS_PROXY_URL:-}"
NO_PROXY_LIST="${NO_PROXY_LIST:-localhost,127.0.0.1,10.42.0.0/16,10.43.0.0/16,.svc,.cluster.local}"

export DEBIAN_FRONTEND=noninteractive
if [[ -n "${HTTP_PROXY_URL}" ]]; then
  export HTTP_PROXY="${HTTP_PROXY_URL}"
  export http_proxy="${HTTP_PROXY_URL}"
fi
if [[ -n "${HTTPS_PROXY_URL}" ]]; then
  export HTTPS_PROXY="${HTTPS_PROXY_URL}"
  export https_proxy="${HTTPS_PROXY_URL}"
fi
export NO_PROXY="${NO_PROXY_LIST}"
export no_proxy="${NO_PROXY_LIST}"

echo "== APT packages =="
apt-get update
apt-get install -y \
  curl git vim htop tmux unzip ca-certificates net-tools jq tree tar \
  bash-completion iptables iproute2 dnsutils ncdu python3 python3-pip zip \
  docker.io docker-compose-v2

echo "== Docker =="
systemctl enable --now docker
usermod -aG docker "${WORKSHOP_USER}" || true

if [[ -n "${HTTP_PROXY_URL}${HTTPS_PROXY_URL}" ]]; then
  echo "== Docker proxy =="
  mkdir -p /etc/systemd/system/docker.service.d
  cat > /etc/systemd/system/docker.service.d/http-proxy.conf << EOF
[Service]
Environment="HTTP_PROXY=${HTTP_PROXY_URL}"
Environment="HTTPS_PROXY=${HTTPS_PROXY_URL}"
Environment="NO_PROXY=${NO_PROXY_LIST}"
EOF
  mkdir -p "/home/${WORKSHOP_USER}/.docker"
  cat > "/home/${WORKSHOP_USER}/.docker/config.json" << EOF
{
  "proxies": {
    "default": {
      "httpProxy": "${HTTP_PROXY_URL}",
      "httpsProxy": "${HTTPS_PROXY_URL}",
      "noProxy": "${NO_PROXY_LIST}"
    }
  }
}
EOF
  chown -R "${WORKSHOP_USER}:${WORKSHOP_USER}" "/home/${WORKSHOP_USER}/.docker"
  systemctl daemon-reload
  systemctl restart docker
fi

echo "== Home for ${WORKSHOP_USER} =="
mkdir -p "/home/${WORKSHOP_USER}/.kube"
chown -R "${WORKSHOP_USER}:${WORKSHOP_USER}" "/home/${WORKSHOP_USER}/.kube"

echo "== kubectl ${KUBECTL_VERSION} =="
cd /tmp
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl

echo "== k9s =="
rm -rf /tmp/k9s-install
mkdir -p /tmp/k9s-install
cd /tmp/k9s-install
curl -L "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_${ARCH}.tar.gz" -o k9s.tar.gz
tar -xzf k9s.tar.gz
install -o root -g root -m 0755 k9s /usr/local/bin/k9s
cd /tmp
rm -rf /tmp/k9s-install

echo "== kubectx / kubens =="
rm -rf /opt/kubectx
git clone https://github.com/ahmetb/kubectx /opt/kubectx
ln -sf /opt/kubectx/kubectx /usr/local/bin/kubectx
ln -sf /opt/kubectx/kubens /usr/local/bin/kubens
chmod +x /opt/kubectx/kubectx /opt/kubectx/kubens

echo "== K3s single-node =="
if ! command -v k3s >/dev/null 2>&1; then
  curl -sfL https://get.k3s.io | sh -
else
  echo "K3s already installed."
fi
systemctl enable --now k3s

echo "== kubeconfig for ${WORKSHOP_USER} =="
mkdir -p "/home/${WORKSHOP_USER}/.kube"
cp /etc/rancher/k3s/k3s.yaml "/home/${WORKSHOP_USER}/.kube/config"
chown -R "${WORKSHOP_USER}:${WORKSHOP_USER}" "/home/${WORKSHOP_USER}/.kube"
chmod 600 "/home/${WORKSHOP_USER}/.kube/config"

echo "== Bash helpers =="
cat > "/home/${WORKSHOP_USER}/.k8s-workshop-bashrc" << EOF
# Kubernetes workshop helpers
alias k='kubectl'
export KUBECONFIG=/home/${WORKSHOP_USER}/.kube/config
if command -v kubectl >/dev/null 2>&1; then
  source <(kubectl completion bash) 2>/dev/null || true
  complete -o default -F __start_kubectl k 2>/dev/null || true
fi
EOF
grep -qxF "source ~/.k8s-workshop-bashrc" "/home/${WORKSHOP_USER}/.bashrc" || echo "source ~/.k8s-workshop-bashrc" >> "/home/${WORKSHOP_USER}/.bashrc"
chown "${WORKSHOP_USER}:${WORKSHOP_USER}" "/home/${WORKSHOP_USER}/.bashrc" "/home/${WORKSHOP_USER}/.k8s-workshop-bashrc"

echo "== Verification =="
kubectl version --client=true
kubectl get nodes || true
docker version || true
docker compose version || true
k9s version || true
kubectx --help >/dev/null && echo "kubectx OK"
kubens --help >/dev/null && echo "kubens OK"

echo "Installation finished."
echo "Docker group was added for user: ${WORKSHOP_USER}. To activate it in current shell: newgrp docker"
