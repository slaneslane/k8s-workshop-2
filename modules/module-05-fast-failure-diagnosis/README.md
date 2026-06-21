# Module 5 — Fast Failure Diagnosis

## Goal

Classify a failing Pod before trying to fix it.

Run one scenario at a time. Start from the healthy state created in Module 4.

## Scenario 1 — ImagePullBackOff

```bash
kubectl apply -n k8s-workshop -f 01-imagepullbackoff.yaml
kubectl -n k8s-workshop get pods
kubectl -n k8s-workshop describe pod <new-pod-name>
kubectl -n k8s-workshop get events --sort-by=.lastTimestamp
```

Expected symptom: `ErrImagePull` followed by `ImagePullBackOff`.

Recovery:

```bash
kubectl apply -n k8s-workshop -f k8s/base/06-app-deployment.yaml
kubectl -n k8s-workshop rollout status deployment/flask-app --timeout=120s
```

## Scenario 2 — CrashLoopBackOff

```bash
kubectl apply -n k8s-workshop -f 02-crashloopbackoff.yaml
kubectl -n k8s-workshop get pods
kubectl -n k8s-workshop logs <pod-name>
kubectl -n k8s-workshop logs <pod-name> --previous
kubectl -n k8s-workshop describe pod <pod-name>
```

Expected symptom: the container starts, exits with status code `1`, and Kubernetes
restarts it with increasing backoff.

Recovery:

First fix with following command:

          command: ["sh", "-c"]
          args:
            - |
              while true; do
                echo "Application running..."
                sleep 5
              done

```bash
kubectl apply -n k8s-workshop -f k8s/base/06-app-deployment.yaml
kubectl -n k8s-workshop rollout status deployment/flask-app --timeout=120s
```

## Scenario 3 — Running but not Ready

```bash
kubectl apply -n k8s-workshop -f 03-readiness-failure.yaml
kubectl -n k8s-workshop get pods
kubectl -n k8s-workshop describe pod <pod-name>
kubectl -n k8s-workshop get endpoints flask-app
```

Expected symptom: the container remains `Running`, but the Pod is `0/1 Ready`
because the readiness probe uses a wrong path.

Recovery:

```bash
kubectl apply -n k8s-workshop -f k8s/base/06-app-deployment.yaml
kubectl -n k8s-workshop rollout status deployment/flask-app --timeout=120s
```
