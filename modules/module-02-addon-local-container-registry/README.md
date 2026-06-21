# Module 2 Add-on — Local Container Registry

## Goal

Build the workshop images, tag them for the local registry, and push them so K3s
can pull them.

## Start and verify the registry

The repository script configures Docker and K3s for the local registry:

```bash
chmod +x scripts/setup-local-registry.sh
./scripts/setup-local-registry.sh

docker ps --filter name=local-registry
curl http://localhost:5000/v2/_catalog
```

## Build, tag, and push the images

Build directly with the final registry tag:

```bash
docker build -f docker/Dockerfile.debug \
  -t localhost:5000/k8s-workshop-app:debug .

docker build -f docker/Dockerfile.distroless \
  -t localhost:5000/k8s-workshop-app:distroless .

docker build -f docker/Dockerfile.migration \
  -t localhost:5000/k8s-workshop-migration:debug .

docker build -f docker/Dockerfile.migration \
  -t localhost:5000/k8s-workshop-migration:broken .

docker build -f docker/Dockerfile.migration \
  -t localhost:5000/k8s-workshop-migration:repair .

docker push localhost:5000/k8s-workshop-app:debug
docker push localhost:5000/k8s-workshop-app:distroless
docker push localhost:5000/k8s-workshop-migration:debug
docker push localhost:5000/k8s-workshop-migration:broken
docker push localhost:5000/k8s-workshop-migration:repair
```

Alternative explicit tagging flow:

```bash
docker build -f docker/Dockerfile.debug -t k8s-workshop-app:debug .
docker tag k8s-workshop-app:debug \
  localhost:5000/k8s-workshop-app:debug
docker push localhost:5000/k8s-workshop-app:debug
```

## Verify

```bash
curl http://localhost:5000/v2/_catalog
curl http://localhost:5000/v2/k8s-workshop-app/tags/list
curl http://localhost:5000/v2/k8s-workshop-migration/tags/list

docker images | grep k8s-workshop
```

## Image references used by Kubernetes

```text
localhost:5000/k8s-workshop-app:debug
localhost:5000/k8s-workshop-app:distroless
localhost:5000/k8s-workshop-migration:debug
localhost:5000/k8s-workshop-migration:broken
localhost:5000/k8s-workshop-migration:repair
```

## Recovery

If the registry is unavailable, rerun:

```bash
./scripts/setup-local-registry.sh
```

If an image is missing, rebuild it, tag it with `localhost:5000/`, and push it again.
