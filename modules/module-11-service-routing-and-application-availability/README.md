# Module 11 — Service Routing and Application Availability

## Goal

Diagnose application availability problems caused by a Service configuration.

## Baseline

```bash
kubectl -n k8s-workshop get service flask-app
kubectl -n k8s-workshop get endpoints flask-app
kubectl -n k8s-workshop get endpointslices -l kubernetes.io/service-name=flask-app
```

## Scenario 1 — Service selector mismatch

```bash
kubectl apply -n k8s-workshop -f 01-service-selector-mismatch.yaml

kubectl -n k8s-workshop get service flask-app
kubectl -n k8s-workshop get endpoints flask-app
kubectl -n k8s-workshop get endpointslices -l kubernetes.io/service-name=flask-app
```

Expected symptom: the Service has no endpoints because its selector does not match
the labels on the application Pods.

Recovery:

```bash
kubectl apply -n k8s-workshop -f k8s/base/07-app-service.yaml
kubectl -n k8s-workshop get endpoints flask-app
```

## Scenario 2 — Wrong targetPort

```bash
kubectl apply -n k8s-workshop -f 02-service-wrong-targetport.yaml

kubectl -n k8s-workshop get endpoints flask-app
kubectl -n k8s-workshop port-forward svc/flask-app 8080:80
curl -v http://localhost:8080/healthz
```

Expected symptom: endpoints exist, but the Service sends traffic to port `8081`,
where the application is not listening.

Recovery:

```bash
kubectl apply -n k8s-workshop -f k8s/base/07-app-service.yaml
kubectl -n k8s-workshop port-forward svc/flask-app 8080:80
curl http://localhost:8080/healthz
```
