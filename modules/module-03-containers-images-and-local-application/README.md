# Module 3 — Containers, Images and Local Application

## Goal

Run the application locally before deploying it to Kubernetes.

## Start the local stack

```bash
docker compose -f docker/docker-compose.yaml up --build
```

In another terminal:

```bash
curl http://localhost:8080/healthz
curl http://localhost:8080/readyz
curl http://localhost:8080/version
curl http://localhost:8080/file-log
```

Optional database exercise:

```bash
curl -X POST http://localhost:8080/items \
  -H 'Content-Type: application/json' \
  -d '{"name":"local-item"}'

curl http://localhost:8080/items
```

## Observe

```bash
docker compose -f docker/docker-compose.yaml ps
docker compose -f docker/docker-compose.yaml logs -f
docker image ls | grep k8s-workshop
```

## Recovery / cleanup

```bash
docker compose -f docker/docker-compose.yaml down -v
```

Rebuild the debug image if the local application was changed:

```bash
docker build -f docker/Dockerfile.debug \
  -t localhost:5000/k8s-workshop-app:debug .
docker push localhost:5000/k8s-workshop-app:debug
```
