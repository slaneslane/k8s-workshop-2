# Module 8 — Distroless and No-shell Troubleshooting

## Goal

Run the same application from a distroless image and troubleshoot without assuming that `sh`, `bash`, `curl`, or a package manager exists inside the container.

This module uses:

```text
modules/module-08-distroless-and-no-shell-troubleshooting/
└── 01-distroless-deployment.yaml
```

The healthy reference Deployment is:

```text
k8s/base/06-app-deployment.yaml
```

---

## Lab — Distroless application image

Apply the distroless Deployment:

```bash
kubectl apply -n k8s-workshop \
  -f modules/module-08-distroless-and-no-shell-troubleshooting/01-distroless-deployment.yaml

kubectl -n k8s-workshop rollout status deployment/flask-app --timeout=120s

kubectl -n k8s-workshop get pods
```

Try to enter the container:

```bash
kubectl -n k8s-workshop exec -it deployment/flask-app -- sh
```

Expected result:

```text
exec: "sh": executable file not found
```

This is expected. The image is distroless and does not contain a shell.

---

## Investigate without shell access

Use Kubernetes signals instead:

```bash
kubectl -n k8s-workshop logs deployment/flask-app

kubectl -n k8s-workshop describe deployment/flask-app

kubectl -n k8s-workshop get events --sort-by=.lastTimestamp
```

Check probes and endpoints:

```bash
kubectl -n k8s-workshop get pods
kubectl -n k8s-workshop get endpoints flask-app
```

Takeaway:

```text
No shell does not mean no troubleshooting.
Logs, events, probes and Service endpoints become critical.
```

---

## Optional — ephemeral debug container

If the cluster supports ephemeral containers, attach a temporary BusyBox container to the same Pod:

```bash
POD=$(kubectl -n k8s-workshop get pod -l app=flask-app -o jsonpath='{.items[0].metadata.name}')

kubectl -n k8s-workshop debug -it pod/${POD} --image=busybox:1.36 --target=flask-app -- sh
```

This does not add a shell to the distroless container. It starts a separate debug container in the same Pod.

---

## Recovery

Restore the normal debug image:

```bash
kubectl apply -n k8s-workshop -f k8s/base/06-app-deployment.yaml

kubectl -n k8s-workshop rollout status deployment/flask-app --timeout=120s

kubectl -n k8s-workshop get pods
```

---

## Key takeaways

```text
Debug image
  has shell and tools
  useful for learning and troubleshooting

Distroless image
  no shell
  no package manager
  smaller attack surface
  production-like pattern

Troubleshooting
  use logs
  use describe
  use events
  check probes
  check endpoints
  optionally use kubectl debug
```
