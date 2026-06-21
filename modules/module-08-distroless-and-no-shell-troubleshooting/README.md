# Module 8 — Distroless and No-shell Troubleshooting

## Goal

Run the same application from a distroless image and troubleshoot without assuming
that `sh`, `bash`, `curl`, or a package manager exists inside the container.

## Apply the distroless deployment

```bash
kubectl apply -n k8s-workshop -f 01-distroless-deployment.yaml
kubectl -n k8s-workshop rollout status deployment/flask-app --timeout=120s
```

## Attempt a normal exec session

```bash
kubectl -n k8s-workshop exec -it deployment/flask-app -- sh
```

Expected symptom: the command fails because the distroless image contains no shell.

## Investigate using Kubernetes signals

```bash
kubectl -n k8s-workshop logs deployment/flask-app
kubectl -n k8s-workshop describe deployment/flask-app
kubectl -n k8s-workshop get events --sort-by=.lastTimestamp
```

Use an ephemeral debug container when supported by the cluster:

```bash
POD=$(kubectl -n k8s-workshop get pod -l app=flask-app \
  -o jsonpath='{.items[0].metadata.name}')

kubectl -n k8s-workshop debug -it pod/${POD} \
  --image=busybox:1.36 \
  --target=flask-app \
  -- sh
```

## Recovery

Restore the debug image:

```bash
kubectl apply -n k8s-workshop -f k8s/base/06-app-deployment.yaml
kubectl -n k8s-workshop rollout status deployment/flask-app --timeout=120s
```
