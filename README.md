# Hands-on Kubernetes Troubleshooting Workshop

This repository supports a 2.5-day workshop for mixed Developer + Infrastructure teams.

```text
Build → Deploy → Break → Observe → Debug → Fix → Learn
```

The same Flask application is used throughout the workshop so participants can see how normal application work maps to Kubernetes operations.

## What is inside

```text
app/          Flask application with health, readiness, DB, logging, and stress endpoints
migrations/   SQL migration examples and the normal migration runner
docker/       Dockerfiles and local Docker Compose setup
k8s/          Working Kubernetes manifests: application, database, storage, and policies
modules/      Workshop instructions and controlled troubleshooting scenarios
docs/         Troubleshooting playbooks and cheat sheets
scripts/      VM preparation and local registry setup scripts
```

## Recommended lab VM

```text
Single-node K3s VM
4 vCPU
8 GB RAM
40 GB disk
Ubuntu 24.04
```

## K3s installation

Basic installation:

```bash
curl -sfL https://get.k3s.io | sh -
```

Behind a proxy, export proxy variables before running the installer:

```bash
export HTTP_PROXY=http://proxy.example.com:3128
export HTTPS_PROXY=http://proxy.example.com:3128
export NO_PROXY=localhost,127.0.0.1,10.42.0.0/16,10.43.0.0/16,.svc,.cluster.local

curl -sfL https://get.k3s.io | sh -
```

Verify:

```bash
sudo systemctl status k3s --no-pager
sudo cat /etc/systemd/system/k3s.service.env
kubectl get nodes
```

## Prepare the Ubuntu VM

```bash
sudo scripts/prepare-ubuntu.sh
```

If the environment needs a Docker or K3s proxy, configure the proxy variables in the script before running it.

## Local Docker run

```bash
cd docker
docker compose up --build
```

In another terminal:

```bash
curl http://localhost:8080/healthz
curl http://localhost:8080/readyz
```

Stop the local stack:

```bash
docker compose down -v
```

## Local container registry

Set up and verify the registry:

```bash
chmod +x scripts/setup-local-registry.sh
./scripts/setup-local-registry.sh

docker ps --filter name=local-registry
curl http://localhost:5000/v2/_catalog
```

## Build and push workshop images

The workshop uses a local registry on every single-node K3s VM.

```bash
docker build -f docker/Dockerfile.debug \
  -t localhost:5000/k8s-workshop-app:debug .

docker build -f docker/Dockerfile.distroless \
  -t localhost:5000/k8s-workshop-app:distroless .

docker build -f docker/Dockerfile.migration \
  -t localhost:5000/k8s-workshop-migration:debug .

docker build -f docker/Dockerfile.broken_migration \
  -t localhost:5000/k8s-workshop-migration:broken .

docker build -f docker/Dockerfile.repair_migration \
  -t localhost:5000/k8s-workshop-migration:repair .
```

Push all images:

```bash
docker push localhost:5000/k8s-workshop-app:debug
docker push localhost:5000/k8s-workshop-app:distroless
docker push localhost:5000/k8s-workshop-migration:debug
docker push localhost:5000/k8s-workshop-migration:broken
docker push localhost:5000/k8s-workshop-migration:repair
```

Verify tags:

```bash
curl http://localhost:5000/v2/_catalog
curl http://localhost:5000/v2/k8s-workshop-app/tags/list
curl http://localhost:5000/v2/k8s-workshop-migration/tags/list
```

## Kubernetes quick start

Do not apply the complete stack blindly in one uninterrupted sequence. PostgreSQL must become Ready before the migration Job runs, and the migration Job must complete before the application is deployed.

### 1. Create the namespace and configuration

```bash
kubectl apply -f k8s/base/01-namespace.yaml

kubectl apply -n k8s-workshop \
  -f k8s/base/02-configmap.yaml

kubectl apply -n k8s-workshop \
  -f k8s/base/03-secret.yaml
```

### 2. Deploy PostgreSQL and wait until it is ready

```bash
kubectl apply -n k8s-workshop \
  -f k8s/base/04-postgres-statefulset.yaml

kubectl -n k8s-workshop rollout status \
  statefulset/postgres \
  --timeout=180s
```

### 3. Run the normal database migration Job

The migration runner retries database connections, but the explicit wait below makes the workshop flow deterministic and easier to explain.

```bash
kubectl delete job db-migration \
  -n k8s-workshop \
  --ignore-not-found=true

kubectl apply -n k8s-workshop \
  -f k8s/base/05-migration-job.yaml

kubectl -n k8s-workshop wait \
  --for=condition=complete \
  job/db-migration \
  --timeout=120s

kubectl -n k8s-workshop logs job/db-migration
```

### 4. Deploy the application and Service

```bash
kubectl apply -n k8s-workshop \
  -f k8s/base/06-app-deployment.yaml

kubectl apply -n k8s-workshop \
  -f k8s/base/07-app-service.yaml

kubectl -n k8s-workshop rollout status \
  deployment/flask-app \
  --timeout=120s
```

### 5. Verify

```bash
kubectl -n k8s-workshop get pods,svc,pvc,jobs

kubectl -n k8s-workshop port-forward \
  svc/flask-app \
  8080:80
```

In another terminal:

```bash
curl http://localhost:8080/healthz
curl http://localhost:8080/readyz
curl http://localhost:8080/version
```

## Workshop modules

The working reference manifests are stored in `k8s/`.

The `modules/` directory contains guided exercises and controlled failure scenarios. Each module README describes:

- the goal of the exercise;
- the command that introduces the scenario;
- the expected symptom;
- diagnostic commands;
- the exact recovery step.

Typical troubleshooting flow:

```text
Observe → Describe → Logs → Events → Fix → Verify
```

## Single-node K3s and storage

This workshop can demonstrate:

- `emptyDir`;
- ConfigMap and Secret volumes;
- PVC with `ReadWriteOnce`;
- StatefulSet `volumeClaimTemplates`.

It cannot reliably demonstrate multi-node RWO attachment conflicts. RWX is covered as an architecture and discussion topic.
