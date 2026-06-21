# Module 7 — Volumes and Persistence

## Goal

Compare ephemeral Pod storage with persistent `ReadWriteOnce` PVC storage and inspect ConfigMap / Secret volumes.

This module uses reference lab manifests from:

```text
k8s/storage/
```

There are no module-specific YAML files for Module 7.

---

## Lab 1 — emptyDir

Create the emptyDir version:

```bash
kubectl apply -n k8s-workshop -f k8s/storage/01-emptydir-app.yaml

kubectl -n k8s-workshop rollout status deployment/flask-app-emptydir --timeout=120s
```

Open a port-forward in one terminal:

```bash
kubectl -n k8s-workshop port-forward deployment/flask-app-emptydir 8081:8080
```

In another terminal:

```bash
curl http://localhost:8081/file-log
```

Restart the Pod:

```bash
kubectl -n k8s-workshop delete pod -l app=flask-app-emptydir

kubectl -n k8s-workshop rollout status deployment/flask-app-emptydir --timeout=120s
```

Start the port-forward again and inspect the file log:

```bash
kubectl -n k8s-workshop port-forward deployment/flask-app-emptydir 8081:8080

curl http://localhost:8081/file-log
```

Expected result:

```text
Data stored in emptyDir does not survive Pod recreation.
```

Cleanup:

```bash
kubectl delete -n k8s-workshop -f k8s/storage/01-emptydir-app.yaml
```

---

## Lab 2 — PVC with ReadWriteOnce

Create the PVC version:

```bash
kubectl apply -n k8s-workshop -f k8s/storage/02-pvc-rwo.yaml

kubectl -n k8s-workshop rollout status deployment/flask-app-pvc --timeout=120s

kubectl -n k8s-workshop get pvc
```

Open a port-forward:

```bash
kubectl -n k8s-workshop port-forward deployment/flask-app-pvc 8082:8080
```

In another terminal:

```bash
curl http://localhost:8082/file-log
```

Restart the Pod:

```bash
kubectl -n k8s-workshop delete pod -l app=flask-app-pvc

kubectl -n k8s-workshop rollout status deployment/flask-app-pvc --timeout=120s
```

Start the port-forward again and inspect the file log:

```bash
kubectl -n k8s-workshop port-forward deployment/flask-app-pvc 8082:8080

curl http://localhost:8082/file-log
```

Expected result:

```text
Data stored on the PVC survives Pod recreation.
```

Cleanup:

```bash
kubectl delete -n k8s-workshop -f k8s/storage/02-pvc-rwo.yaml
```

---

## Lab 3 — ConfigMap and Secret volumes

Apply the reader Pod:

```bash
kubectl apply -n k8s-workshop -f k8s/storage/03-configmap-secret-volumes.yaml

kubectl -n k8s-workshop wait --for=condition=Ready pod/volume-reader --timeout=60s
```

Inspect mounted files:

```bash
kubectl -n k8s-workshop exec -it volume-reader -- sh

cat /config/application.properties
cat /secret/password.txt
exit
```

Cleanup:

```bash
kubectl delete -n k8s-workshop -f k8s/storage/03-configmap-secret-volumes.yaml
```

---

## RWX note

RWX is discussed on slides only. This workshop uses single-node K3s, so it cannot reliably demonstrate multi-node RWX behavior or RWO multi-attach conflicts.
