# Kubernetes Workshop Modules

This directory contains the workshop instructions and intentionally faulty manifests.

The working reference manifests are stored in `k8s/`. Module-specific YAML files are
used only to introduce a controlled scenario. After each scenario, restore the
working configuration from `k8s/`.

## Workshop flow

```text
Learn → Deploy → Break → Observe → Investigate → Fix → Verify
```

## Starting point

Before the first Kubernetes module, build and push the three workshop images and
make sure the local registry is available. Then create a clean baseline:

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

## Working with a scenario

1. Read the README in the current module.
2. Apply only the YAML file named in that README.
3. Observe the symptom.
4. Diagnose it with `get`, `describe`, `logs`, and events.
5. Follow the documented recovery step.
6. Verify that the application has returned to a healthy state.

## Useful commands

```bash
kubectl -n k8s-workshop get pods,deploy,sts,svc,pvc,jobs
kubectl -n k8s-workshop get events --sort-by=.lastTimestamp
kubectl -n k8s-workshop describe pod <pod-name>
kubectl -n k8s-workshop logs <pod-name>
kubectl -n k8s-workshop logs <pod-name> --previous

kubectl -n k8s-workshop rollout status deployment/flask-app
kubectl -n k8s-workshop rollout history deployment/flask-app
kubectl -n k8s-workshop rollout restart deployment/flask-app
kubectl -n k8s-workshop rollout undo deployment/flask-app
```

## Recovery patterns

| Resource / scenario | Preferred recovery |
|---|---|
| Deployment, Service, ConfigMap, Secret | Re-apply the corresponding working file from `k8s/` |
| Migration Job | Delete the Job, then re-apply `k8s/base/05-migration-job.yaml` |
| Temporary quota or LimitRange | Delete the module YAML after the exercise |
| Additional storage workload | Delete the workload and PVC created for the storage lab |
| Distroless image switch | Re-apply `k8s/base/06-app-deployment.yaml` |

## Modules included here

- Module 2 Add-on — Local Container Registry
- Module 3 — Containers, Images and Local Application
- Module 4 — First Deployment to Kubernetes
- Module 5 — Fast Failure Diagnosis
- Module 6 — PostgreSQL and Database Migrations
- Module 7 — Volumes and Persistence
- Module 8 — Distroless and No-shell Troubleshooting
- Module 9 — Requests, Limits and Runtime Behavior
- Module 10 — ResourceQuota and LimitRange
- Module 11 — Service Routing and Application Availability
