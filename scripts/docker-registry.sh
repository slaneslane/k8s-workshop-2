#!/usr/bin/env bash
set -euo pipefail

REGISTRY_HOST="localhost"
REGISTRY_PORT="5000"
REGISTRY_NAME="local-registry"
REGISTRY_DIR="/opt/local-registry"
K3S_REGISTRIES_FILE="/etc/rancher/k3s/registries.yaml"

echo "== Local Docker registry setup =="

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed. Install Docker first."
  exit 1
fi

echo
echo "== Creating registry data directory =="
sudo mkdir -p "${REGISTRY_DIR}"
sudo chmod 755 "${REGISTRY_DIR}"

echo
echo "== Starting local registry container =="
if docker ps -a --format '{{.Names}}' | grep -qx "${REGISTRY_NAME}"; then
  docker rm -f "${REGISTRY_NAME}"
fi

docker run -d \
  --name "${REGISTRY_NAME}" \
  --restart always \
  -p "${REGISTRY_PORT}:5000" \
  -v "${REGISTRY_DIR}:/var/lib/registry" \
  registry:2

echo
echo "== Configuring K3s containerd registry mirror =="

sudo mkdir -p /etc/rancher/k3s

sudo tee "${K3S_REGISTRIES_FILE}" >/dev/null <<EOF
mirrors:
  "localhost:${REGISTRY_PORT}":
    endpoint:
      - "http://localhost:${REGISTRY_PORT}"
  "127.0.0.1:${REGISTRY_PORT}":
    endpoint:
      - "http://127.0.0.1:${REGISTRY_PORT}"

configs:
  "localhost:${REGISTRY_PORT}":
    tls:
      insecure_skip_verify: true
  "127.0.0.1:${REGISTRY_PORT}":
    tls:
      insecure_skip_verify: true
EOF

echo
echo "== Restarting K3s =="
sudo systemctl restart k3s

echo
echo "== Waiting for K3s node =="
sleep 10
kubectl get nodes || true

echo
echo "== Testing registry with busybox =="
docker pull busybox:latest
docker tag busybox:latest localhost:${REGISTRY_PORT}/busybox:latest
docker push localhost:${REGISTRY_PORT}/busybox:latest

echo
echo "== Testing Kubernetes pull from local registry =="

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: registry-test
spec:
  restartPolicy: Never
  containers:
    - name: busybox
      image: localhost:${REGISTRY_PORT}/busybox:latest
      imagePullPolicy: Always
      command: ["sh", "-c", "echo local-registry-ok && sleep 5"]
EOF

kubectl wait --for=condition=Ready pod/registry-test --timeout=60s || true
kubectl logs registry-test || true
kubectl delete pod registry-test --ignore-not-found=true

echo
echo "== Done =="
echo
echo "Use this pattern for workshop images:"
echo
echo "  docker build -t localhost:${REGISTRY_PORT}/k8s-workshop-app:debug -f docker/Dockerfile.debug ."
echo "  docker push localhost:${REGISTRY_PORT}/k8s-workshop-app:debug"
echo
echo "In Kubernetes manifests use:"
echo
echo "  image: localhost:${REGISTRY_PORT}/k8s-workshop-app:debug"
echo "  imagePullPolicy: Always"