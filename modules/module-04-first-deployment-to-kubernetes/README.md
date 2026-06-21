# Module 4 — First Deployment to Kubernetes

## Goal

Deploy the reference application and verify the healthy baseline.

## Apply the base manifests

```bash
kubectl apply -f k8s/base/01-namespace.yaml
kubectl apply -n k8s-workshop -f k8s/base/02-configmap.yaml
kubectl apply -n k8s-workshop -f k8s/base/03-secret.yaml
kubectl apply -n k8s-workshop -f k8s/base/04-postgres-statefulset.yaml

kubectl -n k8s-workshop rollout status statefulset/postgres --timeout=180s

kubectl delete job db-migration -n k8s-workshop --ignore-not-found=true
kubectl apply -n k8s-workshop -f k8s/base/05-migration-job.yaml
kubectl -n k8s-workshop wait --for=condition=complete job/db-migration --timeout=120s

kubectl apply -n k8s-workshop -f k8s/base/06-app-deployment.yaml
kubectl apply -n k8s-workshop -f k8s/base/07-app-service.yaml
kubectl -n k8s-workshop rollout status deployment/flask-app --timeout=120s
```

## Verify

```bash
kubectl -n k8s-workshop get pods,svc,pvc,jobs

kubectl -n k8s-workshop port-forward svc/flask-app 8080:80
```

In another terminal:

```bash
curl http://localhost:8080/healthz
curl http://localhost:8080/readyz
curl http://localhost:8080/version
```

## Recovery

The commands above are idempotent except for the Job. If the migration Job must be
run again, delete it first:

```bash
kubectl delete job db-migration -n k8s-workshop --ignore-not-found=true
kubectl apply -n k8s-workshop -f k8s/base/05-migration-job.yaml
```
