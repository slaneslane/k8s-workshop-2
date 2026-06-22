# Module 9 — Requests, Limits and Runtime Behavior

## Goal

Observe how memory limits work at runtime and diagnose `OOMKilled`.

This module uses a separate Deployment:

```text
flask-app-oom
```

It does not replace the normal `flask-app` Deployment.

Module file:

```text
modules/module-09-requests-limits-and-runtime-behavior/
└── 01-low-memory-oom.yaml
```

The manifest sets:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 64Mi
  limits:
    cpu: 500m
    memory: 96Mi
```

---

## Lab — OOMKilled

Apply the low-memory Deployment:

```bash
kubectl apply -n k8s-workshop \
  -f modules/module-09-requests-limits-and-runtime-behavior/01-low-memory-oom.yaml

kubectl -n k8s-workshop rollout status deployment/flask-app-oom --timeout=120s

kubectl -n k8s-workshop get pods
```

Open a port-forward:

```bash
kubectl -n k8s-workshop port-forward deployment/flask-app-oom 8081:8080
```

In another terminal, request more memory than the 96Mi limit:

```bash
curl "http://localhost:8081/stress/memory?mib=256"
```

---

## Observe

Watch Pod behavior:

```bash
kubectl -n k8s-workshop get pods -w
```

Inspect the Pod:

```bash
kubectl -n k8s-workshop describe pod -l app=flask-app-oom
```

Check previous container logs:

```bash
kubectl -n k8s-workshop logs -l app=flask-app-oom --previous
```

Expected symptom:

```text
Reason: OOMKilled
Exit Code: 137
```

---

## What happened?

The application tried to allocate more memory than the container limit:

```text
requested by endpoint: 256 MiB
container limit:       96 MiB
```

Kubernetes does not slowly throttle memory.

If the process exceeds the memory limit, the kernel kills it.

---

## CPU vs memory behavior

```text
CPU over limit
  → throttled
  → process continues, but slower

Memory over limit
  → OOMKilled
  → process is terminated
```

---

## Recovery / cleanup

Delete only the OOM lab Deployment:

```bash
kubectl delete -n k8s-workshop \
  -f modules/module-09-requests-limits-and-runtime-behavior/01-low-memory-oom.yaml
```

The normal `flask-app` Deployment remains unchanged.

---

## Key takeaways

```text
request
  what the scheduler uses for placement

limit
  maximum runtime usage

CPU limit
  throttling

memory limit
  OOMKilled

OOMKilled
  check describe pod and previous logs
```
