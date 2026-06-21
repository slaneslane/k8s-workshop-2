# Kubernetes Troubleshooting Playbook

## First classification

```text
Is the Pod created?
  No  -> check Deployment/ReplicaSet/events/quota
  Yes -> continue

Is it Pending?
  -> scheduler events, resources, PVC, node capacity, quota

Is it ImagePullBackOff?
  -> image name, tag, registry access, imagePullSecret, proxy

Is it CrashLoopBackOff?
  -> logs --previous, command/args, env vars, app errors, secrets

Is it Running but not Ready?
  -> readiness probe, dependency health, Service, DB, app endpoint

Is it OOMKilled?
  -> memory limit, actual usage, workload behavior

Service not routing?
  -> selector, endpoints, port, targetPort

Data disappeared?
  -> emptyDir vs PVC, mountPath, Pod recreation
```

## Commands

```bash
kubectl get pods -o wide
kubectl describe pod <pod>
kubectl logs <pod>
kubectl logs <pod> --previous
kubectl get events --sort-by=.lastTimestamp
kubectl get deploy,rs,pod,svc,endpoints,pvc
kubectl rollout status deploy/<name>
kubectl rollout history deploy/<name>
kubectl rollout undo deploy/<name>
kubectl debug -it pod/<pod> --image=busybox:1.36 --target=<container> -- sh
```
