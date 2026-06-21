# Requests, limits and quotas

## Requests

Requests are used by the scheduler. They describe the amount of CPU/memory Kubernetes should assume the container needs.

## Limits

Limits are runtime boundaries. CPU can be throttled. Memory above the limit can cause OOMKilled.

## ResourceQuota

ResourceQuota limits aggregate resource usage in a namespace. If new objects exceed quota, creation can be denied or Pods can remain Pending depending on the case.

## LimitRange

LimitRange can set defaults and min/max bounds for containers in a namespace.

## Key message

Requests are counted for scheduling and quota, but they are not the same as actual runtime usage.
