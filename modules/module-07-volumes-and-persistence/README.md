# Module 7 — Volumes and Persistence

## Goal

Compare ephemeral `emptyDir` storage with persistent `ReadWriteOnce` PVC storage.
Also inspect ConfigMap and Secret volumes.

The manifests for this guided lab are reference configurations and remain in
`k8s/storage/`.

## Lab 1 — emptyDir

```bash
kubectl apply -n k8s-workshop -f k8s/storage/01-emptydir-app.yaml
kubectl -n k8s-workshop rollout status deployment/flask-app-emptydir --timeout=120s

kubectl -n k8s-workshop port-forward deployment/flask-app-emptydir 8081:8080
```

In a second terminal, wait for file logs and inspect them:

```bash
curl http://localhost:8081/file-log
```

Delete the Pod and let the Deployment recreate it:

```bash
kubectl -n k8s-workshop delete pod -l app=flask-app-emptydir
```

Inspect `/file-log` again. The `emptyDir` contents are tied to the deleted Pod and
should not survive Pod recreation.

Cleanup:

```bash
kubectl delete -n k8s-workshop -f k8s/storage/01-emptydir-app.yaml
```

## Lab 2 — PVC with ReadWriteOnce

```bash
kubectl apply -n k8s-workshop -f k8s/storage/02-pvc-rwo.yaml
kubectl -n k8s-workshop rollout status deployment/flask-app-pvc --timeout=120s
kubectl -n k8s-workshop get pvc
kubectl -n k8s-workshop port-forward deployment/flask-app-pvc 8082:8080
```

Inspect the file log, delete the Pod, wait for the replacement Pod, then inspect the
file log again:

```bash
curl http://localhost:8082/file-log
kubectl -n k8s-workshop delete pod -l app=flask-app-pvc
curl http://localhost:8082/file-log
```

The file should survive because it is stored on the PVC.

Cleanup:

```bash
kubectl delete -n k8s-workshop -f k8s/storage/02-pvc-rwo.yaml
```

## Lab 3 — ConfigMap and Secret volumes

```bash
kubectl apply -n k8s-workshop -f k8s/storage/03-configmap-secret-volumes.yaml
kubectl -n k8s-workshop exec -it volume-reader -- sh

cat /config/application.properties
cat /secret/password.txt
exit

kubectl delete -n k8s-workshop -f k8s/storage/03-configmap-secret-volumes.yaml
```

## Note about RWX

RWX is discussed in slides only. This workshop uses single-node K3s, so it cannot
demonstrate the multi-node behavior that makes RWX most relevant.
