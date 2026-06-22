# Module 10 — ResourceQuota and LimitRange

## Goal

Understand namespace-level guardrails:

```text
LimitRange
  per-container defaults and min/max values

ResourceQuota
  total namespace budget
```

This module uses:

```text
k8s/resources/
├── 01-limitrange.yaml
└── 02-resourcequota.yaml

modules/module-10-resourcequota-and-limitrange/
├── 01-small-resourcequota.yaml
└── 02-pod-exceeding-limitrange.yaml
```

No old `challenges/`, `solutions/`, `broken.yaml`, or `fixed.yaml` paths are used here.

---

## Lab 10A — Apply the reference policies

Apply the normal workshop policies:

```bash
kubectl apply -n k8s-workshop -f k8s/resources/01-limitrange.yaml

kubectl apply -n k8s-workshop -f k8s/resources/02-resourcequota.yaml
```

Inspect them:

```bash
kubectl -n k8s-workshop describe limitrange default-container-limits

kubectl -n k8s-workshop describe resourcequota workshop-quota
```

What this means:

```text
LimitRange
  defaultRequest → default requests if missing
  default        → default limits if missing
  min            → smallest allowed request/limit
  max            → largest allowed request/limit

ResourceQuota
  total allowed requests, limits, pods, PVCs and storage in the namespace
```

---

## Lab 10B — Quota exceeded

This lab applies a smaller ResourceQuota and then tries to scale the application.

Apply the small quota:

```bash
kubectl apply -n k8s-workshop \
  -f modules/module-10-resourcequota-and-limitrange/01-small-resourcequota.yaml
```

Scale the app:

```bash
kubectl -n k8s-workshop scale deployment/flask-app --replicas=5
```

Observe:

```bash
kubectl -n k8s-workshop get deployment,replicaset,pods

kubectl -n k8s-workshop describe resourcequota module10-small-quota

kubectl -n k8s-workshop get events --sort-by=.lastTimestamp
```

Expected symptom:

```text
The Deployment wants more replicas than the namespace quota allows.
You may see FailedCreate events on the ReplicaSet.
Some Pods may never be created.
```

Important:

```text
Quota is checked when Kubernetes tries to create resources.
This may fail before a Pod object exists.
So there may be no Pending Pod to describe.
```

Recovery:

```bash
kubectl -n k8s-workshop scale deployment/flask-app --replicas=1

kubectl delete -n k8s-workshop \
  -f modules/module-10-resourcequota-and-limitrange/01-small-resourcequota.yaml
```

---

## Lab 10C — LimitRange maximum

This lab creates a Pod that exceeds the per-container maximum from the LimitRange.

Make sure the LimitRange exists:

```bash
kubectl apply -n k8s-workshop -f k8s/resources/01-limitrange.yaml
```

Try to create a Pod that is too large:

```bash
kubectl apply -n k8s-workshop \
  -f modules/module-10-resourcequota-and-limitrange/02-pod-exceeding-limitrange.yaml
```

Expected symptom:

```text
The API server rejects the Pod.
The requested CPU and memory exceed the LimitRange maximum.
```

Observe:

```bash
kubectl -n k8s-workshop get pods

kubectl -n k8s-workshop get events --sort-by=.lastTimestamp

kubectl -n k8s-workshop describe limitrange default-container-limits
```

Recovery:

```bash
kubectl delete pod module10-too-large -n k8s-workshop --ignore-not-found=true
```

---

## Cleanup

After the module, remove the reference policies unless you need them for another demonstration:

```bash
kubectl delete -n k8s-workshop -f k8s/resources/01-limitrange.yaml --ignore-not-found=true

kubectl delete -n k8s-workshop -f k8s/resources/02-resourcequota.yaml --ignore-not-found=true

kubectl -n k8s-workshop scale deployment/flask-app --replicas=1
```

---

## Key takeaways

```text
LimitRange
  per-container guardrails
  can inject default requests and limits
  can reject too-small or too-large containers

ResourceQuota
  namespace budget
  counts total requests, limits, pods, PVCs and storage

Quota exceeded
  often appears as FailedCreate events
  a Pod may not exist at all

LimitRange exceeded
  object can be rejected immediately by the API server
```
