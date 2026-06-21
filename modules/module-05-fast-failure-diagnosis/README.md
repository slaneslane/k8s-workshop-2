# Module 5 — Fast Failure Diagnosis

## Goal

Classify a failing Pod before trying to fix it.

Start from the healthy baseline created in Module 4.

This module contains intentionally faulty manifests in this directory:

```text
modules/module-05-fast-failure-diagnosis/
├── 01-imagepullbackoff.yaml
├── 02-crashloopbackoff.yaml
└── 03-readiness-failure.yaml
```

The working reference configuration is in:

```text
k8s/base/06-app-deployment.yaml
```

Do not use any old `challenges/` or `solutions/` paths in this module.

---

## Scenario 1 — ImagePullBackOff

Apply the scenario manifest:

```bash
cd ~/k8s-workshop-2

kubectl apply -n k8s-workshop -f modules/module-05-fast-failure-diagnosis/01-imagepullbackoff.yaml
```

Observe:

```bash
kubectl -n k8s-workshop get pods
kubectl -n k8s-workshop describe pod <pod-name>
kubectl -n k8s-workshop get events --sort-by=.lastTimestamp
```

Expected symptom:

```text
ErrImagePull
ImagePullBackOff
```

Focus question:

```text
Did the container start?
Where does Kubernetes show image pull errors?
```

Recovery will be discussed by the instructor.

---

## Scenario 2 — CrashLoopBackOff

Apply the scenario manifest:

```bash
cd ~/k8s-workshop-2

kubectl apply -n k8s-workshop -f modules/module-05-fast-failure-diagnosis/02-crashloopbackoff.yaml
```

Observe:

```bash
kubectl -n k8s-workshop get pods
kubectl -n k8s-workshop logs <pod-name>
kubectl -n k8s-workshop logs <pod-name> --previous
kubectl -n k8s-workshop describe pod <pod-name>
```

Expected symptom:

```text
CrashLoopBackOff
```

Focus question:

```text
Did the image pull successfully?
What does the previous container log say?
```

Recovery will be discussed by the instructor.

---

## Scenario 3 — Running but not Ready

Apply the scenario manifest:

```bash
cd ~/k8s-workshop-2

kubectl apply -n k8s-workshop -f modules/module-05-fast-failure-diagnosis/03-readiness-failure.yaml
```

Observe:

```bash
kubectl -n k8s-workshop get pods
kubectl -n k8s-workshop describe pod <pod-name>
kubectl -n k8s-workshop get endpoints flask-app
kubectl -n k8s-workshop logs <pod-name>
```

Expected symptom:

```text
Running
0/1 Ready
```

Focus question:

```text
Is the process running?
Is the Pod allowed to receive Service traffic?
```

Recovery will be discussed by the instructor.

---

## After each scenario

Wait for the instructor to confirm recovery, then verify:

```bash
kubectl -n k8s-workshop rollout status deployment/flask-app --timeout=120s
kubectl -n k8s-workshop get pods
kubectl -n k8s-workshop get endpoints flask-app
```

The goal is not to memorize the fix.

The goal is to classify the failure correctly.
