# Module 6 — PostgreSQL and Database Migrations

## Goal

Use Kubernetes Jobs for database work and learn how to diagnose and recover from migration problems.

This module uses the existing working manifests in `k8s/base/` and three module files:

```text
modules/module-06-postgresql-and-database-migrations/
├── 01-wrong-database-secret.yaml
├── 02-broken-migration-job.yaml
└── 03-repair-migration-job.yaml
```

## Start clean

Do not delete PostgreSQL or its PVC.

Delete only old Jobs, so they can be run again:

```bash
kubectl delete job \
  db-migration \
  db-migration-broken \
  db-migration-repair \
  -n k8s-workshop \
  --ignore-not-found=true
```

Make sure PostgreSQL is running:

```bash
kubectl apply -n k8s-workshop \
  -f k8s/base/04-postgres-statefulset.yaml

kubectl -n k8s-workshop rollout status \
  statefulset/postgres \
  --timeout=180s
```

---

## Lab 1 — Run the normal migration

```bash
kubectl apply -n k8s-workshop \
  -f k8s/base/05-migration-job.yaml

kubectl -n k8s-workshop wait \
  --for=condition=complete \
  job/db-migration \
  --timeout=120s

kubectl -n k8s-workshop logs job/db-migration
```

Expected result:

```text
Migrations completed.
```

If you need to run it again:

```bash
kubectl delete job db-migration \
  -n k8s-workshop \
  --ignore-not-found=true
```

Then apply the Job again.

---

## Lab 2 — Wrong database Secret

Apply the scenario:

```bash
kubectl apply -n k8s-workshop \
  -f modules/module-06-postgresql-and-database-migrations/01-wrong-database-secret.yaml
```

Observe:

```bash
kubectl -n k8s-workshop get pods
kubectl -n k8s-workshop describe pod <flask-app-pod>
kubectl -n k8s-workshop logs deployment/flask-app
kubectl -n k8s-workshop get endpoints flask-app
```

Expected symptom:

```text
Application is Running, but readiness may fail.
The app cannot authenticate to PostgreSQL.
```

Recover:

```bash
kubectl apply -n k8s-workshop \
  -f k8s/base/03-secret.yaml

kubectl apply -n k8s-workshop \
  -f k8s/base/06-app-deployment.yaml

kubectl -n k8s-workshop rollout status \
  deployment/flask-app \
  --timeout=120s
```

---

## Lab 3 — Broken SQL migration

This runs a real SQL file from a separate migration image:

```text
localhost:5000/k8s-workshop-migration:broken
```

It creates an isolated schema called `workshop_training` and then fails on purpose.

Run it:

```bash
kubectl delete job db-migration-broken \
  -n k8s-workshop \
  --ignore-not-found=true

kubectl apply -n k8s-workshop \
  -f modules/module-06-postgresql-and-database-migrations/02-broken-migration-job.yaml

kubectl -n k8s-workshop get jobs,pods
kubectl -n k8s-workshop logs job/db-migration-broken
kubectl -n k8s-workshop describe job db-migration-broken
```

Expected symptom:

```text
ERROR: column "migration_marker" of relation "partial_migration" already exists
```

Inspect the partial state:

```bash
kubectl -n k8s-workshop exec statefulset/postgres -- \
  psql -U workshop -d workshop -c \
  "SELECT table_schema, table_name
   FROM information_schema.tables
   WHERE table_schema = 'workshop_training';"
```

---

## Lab 4 — Repair the failed migration

Run the repair Job:

```bash
kubectl delete job db-migration-repair \
  -n k8s-workshop \
  --ignore-not-found=true

kubectl apply -n k8s-workshop \
  -f modules/module-06-postgresql-and-database-migrations/03-repair-migration-job.yaml

kubectl -n k8s-workshop wait \
  --for=condition=complete \
  job/db-migration-repair \
  --timeout=120s

kubectl -n k8s-workshop logs job/db-migration-repair
```

Verify cleanup:

```bash
kubectl -n k8s-workshop exec statefulset/postgres -- \
  psql -U workshop -d workshop -c \
  "SELECT table_schema, table_name
   FROM information_schema.tables
   WHERE table_schema = 'workshop_training';"
```

Expected result:

```text
0 rows
```

---

## Cleanup

```bash
kubectl delete job \
  db-migration \
  db-migration-broken \
  db-migration-repair \
  -n k8s-workshop \
  --ignore-not-found=true
```

Keep PostgreSQL and the PVC.

## Key takeaways

```text
Do not delete PostgreSQL for this module.
Jobs must be deleted before they can be run again with the same name.
A failed migration can leave partial database state.
Repair should be explicit, observable, and repeatable.
```
