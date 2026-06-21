# Volumes in this workshop

## Ephemeral

`emptyDir` lives with the Pod. It survives container restarts, but does not survive Pod recreation.

## ConfigMap and Secret volumes

Configuration and credentials can be mounted as files. They are not a replacement for persistent data storage.

## PVC with RWO

A `PersistentVolumeClaim` requests storage. In K3s, the default `local-path` StorageClass can dynamically provision local volumes. `ReadWriteOnce` means the volume can be mounted read-write by a single node.

On a single-node K3s cluster you cannot reliably demonstrate multi-node attach conflicts.

## RWX

`ReadWriteMany` allows many Pods/nodes to mount a volume read-write. It requires a storage backend such as NFS, CephFS, EFS, Azure Files or similar.

## RWOP

`ReadWriteOncePod` restricts write access to a single Pod in the cluster.
