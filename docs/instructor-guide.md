# Instructor guide

## Recommended timing

Day 1: first deploy, Docker images, ImagePullBackOff, CrashLoopBackOff, readiness.
Day 2: PostgreSQL, migrations, volumes, distroless, resources, quotas, OOMKilled.
Day 3: combined troubleshooting cases and responsibilities.

## Teaching pattern

1. Desired state
2. Apply manifest
3. Observe current state
4. Something fails
5. Use kubectl to diagnose
6. Explain root cause
7. Fix
8. Extract the Kubernetes concept

## Do not over-teach YAML

Let concepts appear from troubleshooting. Participants should learn how to read cluster signals.
