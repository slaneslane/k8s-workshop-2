# Module 6 — PostgreSQL and Database Migrations

## Learning objectives

After this module, participants should be able to:

- Explain why database migrations are executed as Kubernetes Jobs.
- Read Job status, Pod status, logs, and events.
- Differentiate a normal migration from an intentionally failing migration.
- Recognize that a failed migration can leave a partially applied database state.
- Run a separate repair Job and verify recovery.

## Important safety model

The normal migration remains the working reference flow:

```text
k8s/base/05-migration-job.yaml
→ localhost:5000/k8s-workshop-migration:debug
→ normal migration runner
```

The intentionally failing migration is separate:

```text
db-migration-broken
→ localhost:5000/k8s-workshop-migration:broken
→ 999_broken_migration.sql
```

The repair flow is separate too:

```text
db-migration-repair
→ localhost:5000/k8s-workshop-migration:repair
→ 999_repair_migration.sql
```

The broken migration works only in the isolated `workshop_training` schema. It does
not change the application's normal tables.

---

## 1. Prerequisites

Start from a healthy baseline. PostgreSQL must be Ready, and the normal migration
Job must complete successfully.

```bash
kubectl apply -f k8s/base/01-namespace.yaml
kubectl apply -n k8s-workshop -f k8s/base/02-configmap.yaml
kubectl apply -n k8s-workshop -f k8s/base/03-secret.yaml
kubectl apply -n k8s-workshop -f k8s/base/04-postgres-statefulset.yaml

kubectl -n k8s-workshop rollout status statefulset/postgres --timeout=180s

kubectl delete job db-migration -n k8s-workshop --ignore-not-found=true
kubectl apply -n k8s-workshop -f k8s/base/05-migration-job.yaml
kubectl -n k8s-workshop wait --for=condition=complete job/db-migration --timeout=120s
kubectl -n k8s-workshop logs job/db-migration
```

---

## 2. Build and push the workshop-only migration images

Run these commands from the repository root:

```bash
docker build -f docker/Dockerfile.broken_migration \
  -t localhost:5000/k8s-workshop-migration:broken .

docker build -f docker/Dockerfile.repair_migration \
  -t localhost:5000/k8s-workshop-migration:repair .

docker push localhost:5000/k8s-workshop-migration:broken
docker push localhost:5000/k8s-workshop-migration:repair
```

Verify that both tags are visible in the local registry:

```bash
curl http://localhost:5000/v2/k8s-workshop-migration/tags/list
```

Expected tags include:

```text
debug
broken
repair
```

---

## 3. Guided lab: wrong database secret

Apply the scenario:

```bash
kubectl apply -n k8s-workshop -f 01-wrong-database-secret.yaml
kubectl -n k8s-workshop rollout status deployment/flask-app --timeout=120s || true
```

Observe and investigate:

```bash
kubectl -n k8s-workshop get pods
kubectl -n k8s-workshop describe pod <flask-app-pod>
kubectl -n k8s-workshop logs deployment/flask-app
kubectl -n k8s-workshop get endpoints flask-app
```

Expected symptom: the application container can remain Running, but readiness fails
because `/readyz` cannot authenticate to PostgreSQL. A Running Pod is not necessarily
Ready to receive traffic.

### Recovery

Restore the working Secret and Deployment:

```bash
kubectl apply -n k8s-workshop -f k8s/base/03-secret.yaml
kubectl apply -n k8s-workshop -f k8s/base/06-app-deployment.yaml
kubectl -n k8s-workshop rollout status deployment/flask-app --timeout=120s
```

---

## 4. Challenge: real broken SQL migration

This Job runs a real SQL file. The first statements create an isolated schema and
table. The final statement adds the same column twice, producing a real PostgreSQL
error. Because `psql` runs without a surrounding transaction, the successful
statements remain in the database.

Before rerunning the challenge, delete an older Job with the same name:

```bash
kubectl delete job db-migration-broken -n k8s-workshop --ignore-not-found=true
```

Run the challenge:

```bash
kubectl apply -n k8s-workshop -f 02-broken-migration-job.yaml
kubectl -n k8s-workshop get jobs,pods
kubectl -n k8s-workshop logs job/db-migration-broken
kubectl -n k8s-workshop describe job db-migration-broken
```

Expected result:

```text
ERROR:  column "migration_marker" of relation "partial_migration" already exists
```

The Job should eventually report `Failed` after reaching its backoff limit.

### Inspect the partial database state

```bash
kubectl -n k8s-workshop exec statefulset/postgres -- \
  psql -U workshop -d workshop -c \
  "SELECT table_schema, table_name
   FROM information_schema.tables
   WHERE table_schema = 'workshop_training';"

kubectl -n k8s-workshop exec statefulset/postgres -- \
  psql -U workshop -d workshop -c \
  "SELECT column_name
   FROM information_schema.columns
   WHERE table_schema = 'workshop_training'
     AND table_name = 'partial_migration'
   ORDER BY ordinal_position;"
```

You should see the `workshop_training.partial_migration` table and the
`migration_marker` column, even though the Job failed.

---

## 5. Run the repair Job

The repair script is idempotent. It removes only the isolated workshop schema.

```bash
kubectl delete job db-migration-repair -n k8s-workshop --ignore-not-found=true
kubectl apply -n k8s-workshop -f 03-repair-migration-job.yaml

kubectl -n k8s-workshop wait \
  --for=condition=complete \
  job/db-migration-repair \
  --timeout=120s

kubectl -n k8s-workshop logs job/db-migration-repair
```

### Verify recovery

```bash
kubectl -n k8s-workshop exec statefulset/postgres -- \
  psql -U workshop -d workshop -c \
  "SELECT table_schema, table_name
   FROM information_schema.tables
   WHERE table_schema = 'workshop_training';"
```

Expected result: zero rows.

---

## 6. Cleanup

```bash
kubectl delete job db-migration-broken -n k8s-workshop --ignore-not-found=true
kubectl delete job db-migration-repair -n k8s-workshop --ignore-not-found=true
```

The normal application database remains untouched. No additional cleanup is required.

---

## Key takeaways

```text
Application Deployment ≠ Migration Job

A failed migration can leave partial state.

Migrations should be designed to be atomic and idempotent.

Recovery should be deliberate, observable, and repeatable.
```
