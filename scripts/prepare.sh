#!/usr/bin/env bash
set -euo pipefail

KUBECTL_VERSION="v1.30.0"
ARCH="amd64"
WORKSHOP_USER="k8s"

echo "== APT packages =="
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  curl \
  git \
  vim \
  htop \
  tmux \
  unzip \
  ca-certificates \
  net-tools \
  jq \
  tree \
  tar \
  bash-completion \
  iptables \
  iproute2 \
  dnsutils \
  ncdu \
  python3 \
  python3-pip \
  zip \
  docker.io \
  docker-compose-v2

echo
echo "== Docker =="
systemctl enable --now docker
usermod -aG docker "${WORKSHOP_USER}"

echo
echo "== Docker proxy =="

mkdir -p /etc/systemd/system/docker.service.d

cat > /etc/systemd/system/docker.service.d/http-proxy.conf << EOF
[Service]
Environment="HTTP_PROXY=http://<PROXY_HOST>:3128"
Environment="HTTPS_PROXY=http://<PROXY_HOST>:3128"
Environment="NO_PROXY=..."
Environment="http_proxy=http://<PROXY_HOST>:3128"
Environment="https_proxy=http://<PROXY_HOST>:3128"
Environment="no_proxy=..."
EOF

mkdir -p ~/.docker

cat > ~/.docker/config.json <<'EOF'
{
  "proxies": {
    "default": {
      "httpProxy": "http://PROXY_HOST:PROXY_PORT",
      "httpsProxy": "http://PROXY_HOST:PROXY_PORT",
      "noProxy": "localhost,127.0.0.1,::1,localhost:5000,10.42.0.0/16,10.43.0.0/16,.svc,.cluster.local"
    }
  }
}
EOF

systemctl daemon-reload
systemctl restart docker

echo
echo "== Home for ${WORKSHOP_USER} =="
mkdir -p "/home/${WORKSHOP_USER}/.kube"
chown -R "${WORKSHOP_USER}:${WORKSHOP_USER}" "/home/${WORKSHOP_USER}/.kube"

echo
echo "== kubectl ${KUBECTL_VERSION} =="
cd /tmp
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl

echo
echo "== k9s =="
cd /tmp
rm -rf /tmp/k9s-install
mkdir -p /tmp/k9s-install
cd /tmp/k9s-install

curl -L "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_${ARCH}.tar.gz" -o k9s.tar.gz
tar -xzf k9s.tar.gz
install -o root -g root -m 0755 k9s /usr/local/bin/k9s

cd /tmp
rm -rf /tmp/k9s-install

echo
echo "== kubectx / kubens =="
rm -rf /opt/kubectx
git clone https://github.com/ahmetb/kubectx /opt/kubectx

ln -sf /opt/kubectx/kubectx /usr/local/bin/kubectx
ln -sf /opt/kubectx/kubens /usr/local/bin/kubens

chmod +x /opt/kubectx/kubectx
chmod +x /opt/kubectx/kubens

echo
echo "== K3s single-node =="
if ! command -v k3s >/dev/null 2>&1; then
  curl -sfL https://get.k3s.io | sh -
else
  echo "K3s already installed."
fi

systemctl enable --now k3s

echo
echo "== kubeconfig for ${WORKSHOP_USER} =="
mkdir -p "/home/${WORKSHOP_USER}/.kube"
cp /etc/rancher/k3s/k3s.yaml "/home/${WORKSHOP_USER}/.kube/config"
chown -R "${WORKSHOP_USER}:${WORKSHOP_USER}" "/home/${WORKSHOP_USER}/.kube"
chmod 600 "/home/${WORKSHOP_USER}/.kube/config"


echo
echo "== Verification =="
kubectl version --client=true
kubectl get nodes || true

docker version || true
docker compose version || true

k9s version || true
kubectx --help >/dev/null && echo "kubectx OK"
kubens --help >/dev/null && echo "kubens OK"

echo
echo "Installation finished."
echo
echo "Docker group was added for user: ${WORKSHOP_USER}"
echo "To activate docker group in the current shell, run:"
echo
echo "  newgrp docker"
echo
echo "Then test:"
echo
echo "  docker ps"
