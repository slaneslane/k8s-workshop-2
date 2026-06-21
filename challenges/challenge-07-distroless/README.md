# Distroless debugging

## Scenario

Production image has no shell, so kubectl exec -- sh fails.

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

Most relevant command: `kubectl debug or logs`

## Hints

1. First classify the failure state.
2. Check Events before changing YAML.
3. Compare labels, image names, environment variables and resource settings.

## Root cause

no shell in image

## Fix

```bash
kubectl apply -n k8s-workshop -f solution.yaml
```
