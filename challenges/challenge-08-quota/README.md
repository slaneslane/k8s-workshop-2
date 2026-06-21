# ResourceQuota exceeded

## Scenario

Pods remain Pending or creation is denied because the namespace quota is exhausted.

## Expected symptoms

Apply the broken manifest and observe the workload state.

```bash
kubectl apply -n k8s-workshop -f broken.yaml
kubectl -n k8s-workshop get pods
```

## Investigation commands

```bash
kubectl -n k8s-workshop get pods -o wide
kubectl -n k8s-workshop describe pod <pod-name>
kubectl -n k8s-workshop logs <pod-name>
kubectl -n k8s-workshop logs <pod-name> --previous
kubectl -n k8s-workshop get events --sort-by=.lastTimestamp
```

Most relevant command: `kubectl describe quota, kubectl describe pod`

## Hints

1. First classify the failure state.
2. Check Events before changing YAML.
3. Compare labels, image names, environment variables and resource settings.

## Root cause

requests exceed namespace quota

## Fix

```bash
kubectl apply -n k8s-workshop -f solution.yaml
```
