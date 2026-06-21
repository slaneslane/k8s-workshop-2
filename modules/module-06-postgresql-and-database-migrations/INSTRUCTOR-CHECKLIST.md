# Instructor Checklist — Module 6

Before the session (if not already done):

```bash
docker build -f docker/Dockerfile.broken_migration \
  -t localhost:5000/k8s-workshop-migration:broken .
docker build -f docker/Dockerfile.repair_migration \
  -t localhost:5000/k8s-workshop-migration:repair .
docker push localhost:5000/k8s-workshop-migration:broken
docker push localhost:5000/k8s-workshop-migration:repair
```

Before the broken migration challenge:

```bash
kubectl delete job db-migration-broken -n k8s-workshop --ignore-not-found=true
kubectl delete job db-migration-repair -n k8s-workshop --ignore-not-found=true

kubectl -n k8s-workshop exec statefulset/postgres -- \
  psql -U workshop -d workshop -c \
  "DROP SCHEMA IF EXISTS workshop_training CASCADE;"
```

If the wrong-secret exercise was used, restore the base configuration before
starting the migration exercises:

```bash
kubectl apply -n k8s-workshop -f k8s/base/03-secret.yaml
kubectl apply -n k8s-workshop -f k8s/base/06-app-deployment.yaml
kubectl -n k8s-workshop rollout status deployment/flask-app --timeout=120s
```
