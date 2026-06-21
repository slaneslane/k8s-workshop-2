# Module 9 — Requests, Limits and Runtime Behavior

## Goal

Observe a memory limit at runtime and diagnose `OOMKilled`.

The scenario creates a separate deployment named `flask-app-oom`; it does not
replace the working `flask-app` deployment.

## Apply the low-memory deployment

```bash
kubectl apply -n k8s-workshop -f 01-low-memory-oom.yaml
kubectl -n k8s-workshop rollout status deployment/flask-app-oom --timeout=120s

kubectl -n k8s-workshop port-forward deployment/flask-app-oom 8081:8080
```

In another terminal, request more memory than the 96 MiB limit:

```bash
curl "http://localhost:8081/stress/memory?mib=256"
```

## Investigate

```bash
kubectl -n k8s-workshop get pods
kubectl -n k8s-workshop describe pod -l app=flask-app-oom
kubectl -n k8s-workshop logs -l app=flask-app-oom --previous
```

Expected symptom: the container is terminated with `OOMKilled` and exit code `137`.

## Recovery / cleanup

```bash
kubectl delete -n k8s-workshop -f 01-low-memory-oom.yaml
```

The base application remains unchanged.
