# Module 7 — Volumes and Persistence

## Goal

Understand the difference between temporary and persistent storage and learn how ConfigMaps and Secrets can be exposed as files.

This module uses:

```text
k8s/storage/
├── 01-emptydir-app.yaml
├── 02-pvc-rwo.yaml
└── 03-configmap-secret-volumes.yaml
```


---

## Lab 7A — emptyDir

`emptyDir` is temporary storage created for a Pod.

```bash
kubectl apply -n k8s-workshop -f k8s/storage/01-emptydir-app.yaml

kubectl -n k8s-workshop exec flask-app-emptydir -- tail /data/events.log

kubectl -n k8s-workshop delete pod flask-app-emptydir

kubectl apply -n k8s-workshop -f k8s/storage/01-emptydir-app.yaml

kubectl -n k8s-workshop exec flask-app-emptydir -- ls -la /data
```

Expected result:

```text
The old events.log file is gone.
```

Takeaway:

```text
emptyDir lives as long as the Pod lives.
Delete the Pod → emptyDir disappears.
```

Cleanup:

```bash
kubectl delete -n k8s-workshop -f k8s/storage/01-emptydir-app.yaml
```

---

## Lab 7B — PVC RWO

A PersistentVolumeClaim survives Pod recreation.

```bash
kubectl apply -n k8s-workshop -f k8s/storage/02-pvc-rwo.yaml

kubectl -n k8s-workshop rollout status deployment/flask-app-pvc --timeout=120s

kubectl -n k8s-workshop port-forward deployment/flask-app-pvc 8082:8080
```

In another terminal:

```bash
curl http://localhost:8082/file-log
```

Delete the Pod and let Kubernetes recreate it:

```bash
kubectl -n k8s-workshop delete pod -l app=flask-app-pvc

kubectl -n k8s-workshop rollout status deployment/flask-app-pvc --timeout=120s
```

Check the file again:

```bash
curl http://localhost:8082/file-log

kubectl -n k8s-workshop get pvc,pv
```

Expected result:

```text
The file survives Pod recreation.
```

Takeaway:

```text
PVC survives Pod recreation.
RWO means the volume can be mounted read/write by one node at a time.
```

Cleanup:

```bash
kubectl delete -n k8s-workshop -f k8s/storage/02-pvc-rwo.yaml
```

---

## Lab 7C — ConfigMap and Secret volumes

ConfigMap and Secret keys can be mounted as files.

```bash
kubectl apply -n k8s-workshop -f k8s/storage/03-configmap-secret-volumes.yaml

kubectl -n k8s-workshop exec volume-reader -- ls -la /config

kubectl -n k8s-workshop exec volume-reader -- ls -la /secret

kubectl -n k8s-workshop exec volume-reader -- cat /config/application.properties

kubectl -n k8s-workshop exec volume-reader -- cat /secret/password.txt
```

Expected result:

```text
ConfigMap keys become files in /config.
Secret keys become files in /secret.
```

Takeaway:

```text
ConfigMap and Secret can be mounted as files, not only injected as environment variables.
```

Cleanup:

```bash
kubectl delete -n k8s-workshop -f k8s/storage/03-configmap-secret-volumes.yaml
```

---

## PostgreSQL storage pattern

PostgreSQL uses a StatefulSet with `volumeClaimTemplates`:

```text
StatefulSet
    ↓
volumeClaimTemplates
    ↓
PVC
    ↓
Persistent Volume
```

In this workshop:

```text
postgres-0
    ↓
postgres-data-postgres-0
    ↓
Persistent Volume
```

This gives PostgreSQL stable storage across Pod recreation.

It does not provide database HA by itself.

---

## Single-node lab caveat

This workshop uses single-node K3s.

```text
Two Pods on the same node may appear to work with storage patterns
that would behave differently in a multi-node cluster.
```

Important:

```text
Multi-attach errors require multi-node clusters.
RWO semantics are important, but this lab does not prove all production behaviors.
```

Use this module to learn storage semantics and patterns, not full distributed storage behavior.

---

## Key takeaways

```text
emptyDir
  temporary storage
  removed when the Pod is removed

PVC
  persistent storage
  survives Pod recreation

ConfigMap volume
  configuration as files

Secret volume
  sensitive data as files

StatefulSet + volumeClaimTemplates
  stable identity
  dedicated persistent storage per Pod

Single-node K3s
  good for learning semantics
  not enough to demonstrate all multi-node storage behavior
```
