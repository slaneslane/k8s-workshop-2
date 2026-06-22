# Module 11 — Service Routing and Application Availability

## Goal

Diagnose application availability problems caused by Service configuration.

This module uses:

```text
modules/module-11-service-routing-and-application-availability/
├── 01-service-selector-mismatch.yaml
└── 02-service-wrong-targetport.yaml
```

The healthy reference Service is:

```text
k8s/base/07-app-service.yaml
```

No old `challenges/`, `solutions/`, `broken.yaml`, or `fixed.yaml` paths are used here.

---

## Baseline

Start from a healthy application Deployment and Service:

```bash
kubectl apply -n k8s-workshop -f k8s/base/06-app-deployment.yaml

kubectl apply -n k8s-workshop -f k8s/base/07-app-service.yaml

kubectl -n k8s-workshop rollout status deployment/flask-app --timeout=120s
```

Verify Service routing objects:

```bash
kubectl -n k8s-workshop get pods --show-labels

kubectl -n k8s-workshop get service flask-app

kubectl -n k8s-workshop get endpoints flask-app

kubectl -n k8s-workshop get endpointslices -l kubernetes.io/service-name=flask-app
```

Expected baseline:

```text
Service has endpoints.
Endpoints point to Ready flask-app Pods.
```

---

## Lab 11A — Wrong Service selector

Apply the wrong selector Service:

```bash
kubectl apply -n k8s-workshop \
  -f modules/module-11-service-routing-and-application-availability/01-service-selector-mismatch.yaml
```

Observe:

```bash
kubectl -n k8s-workshop get pods --show-labels

kubectl -n k8s-workshop describe service flask-app

kubectl -n k8s-workshop get endpoints flask-app

kubectl -n k8s-workshop get endpointslices -l kubernetes.io/service-name=flask-app
```

Expected symptom:

```text
Application Pods are Running and Ready,
but the Service has no endpoints.
```

Why?

```text
Service selector does not match Pod labels.
No matching Pods → no endpoints → no traffic.
```

Recovery:

```bash
kubectl apply -n k8s-workshop -f k8s/base/07-app-service.yaml

kubectl -n k8s-workshop get endpoints flask-app
```

---

## Lab 11B — Wrong targetPort

Apply the wrong targetPort Service:

```bash
kubectl apply -n k8s-workshop \
  -f modules/module-11-service-routing-and-application-availability/02-service-wrong-targetport.yaml
```

Observe:

```bash
kubectl -n k8s-workshop get endpoints flask-app

kubectl -n k8s-workshop describe service flask-app

kubectl -n k8s-workshop port-forward service/flask-app 8080:80
```

In another terminal:

```bash
curl -v http://localhost:8080/healthz
```

Expected symptom:

```text
Service has endpoints,
but traffic is sent to the wrong container port.
```

Why?

```text
Pod listens on containerPort 8080.
Service sends traffic to targetPort 8081.
Connection fails.
```

Recovery:

```bash
kubectl apply -n k8s-workshop -f k8s/base/07-app-service.yaml

kubectl -n k8s-workshop port-forward service/flask-app 8080:80
```

In another terminal:

```bash
curl http://localhost:8080/healthz
```

---

## Cleanup

Restore the healthy Service:

```bash
kubectl apply -n k8s-workshop -f k8s/base/07-app-service.yaml

kubectl -n k8s-workshop get service,endpoints
```

---

## Key takeaways

```text
Service selector
  decides which Pods become endpoints

Pod labels
  must match the Service selector

Endpoints / EndpointSlices
  show where Service traffic will go

port
  Service port exposed inside the cluster

targetPort
  container port where traffic is forwarded

Ready Pod + wrong Service
  application works, but traffic may not reach it
```
