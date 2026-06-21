# Module 10 — ResourceQuota and LimitRange

## Goal

Observe namespace admission controls.

A ResourceQuota is enforced when Kubernetes attempts to create an object. When the
quota is exceeded, a ReplicaSet can fail to create more Pods; this often appears as
a `FailedCreate` event rather than a Pod that remains Pending.

## Guided lab: reference policies

```bash
kubectl apply -n k8s-workshop -f k8s/resources/01-limitrange.yaml
kubectl apply -n k8s-workshop -f k8s/resources/02-resourcequota.yaml

kubectl -n k8s-workshop describe limitrange default-container-limits
kubectl -n k8s-workshop describe resourcequota workshop-quota
```

## Scenario 1 — Small quota

```bash
kubectl apply -n k8s-workshop -f 01-small-resourcequota.yaml
kubectl -n k8s-workshop scale deployment/flask-app --replicas=5

kubectl -n k8s-workshop get deployment,replicaset,pods
kubectl -n k8s-workshop get events --sort-by=.lastTimestamp
kubectl -n k8s-workshop describe resourcequota module10-small-quota
```

Expected symptom: the Deployment has fewer available replicas than desired and
events report that quota would be exceeded.

Recovery:

```bash
kubectl -n k8s-workshop scale deployment/flask-app --replicas=1
kubectl delete -n k8s-workshop -f 01-small-resourcequota.yaml
```

## Scenario 2 — LimitRange maximum

Apply the workshop LimitRange if it is not present:

```bash
kubectl apply -n k8s-workshop -f k8s/resources/01-limitrange.yaml
kubectl apply -n k8s-workshop -f 02-pod-exceeding-limitrange.yaml
```

Expected symptom: the API server rejects the Pod because the requested limit exceeds
the LimitRange maximum.

Recovery:

```bash
kubectl delete -n k8s-workshop pod module10-too-large --ignore-not-found=true
```

After Module 10, remove the reference policies unless they are needed later:

```bash
kubectl delete -n k8s-workshop -f k8s/resources/01-limitrange.yaml --ignore-not-found=true
kubectl delete -n k8s-workshop -f k8s/resources/02-resourcequota.yaml --ignore-not-found=true
```
