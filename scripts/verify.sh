#!/usr/bin/env bash

echo "== Host =="
hostname
whoami

echo
echo "== kubectl =="
kubectl version --client || true

echo
echo "== k3s =="
k3s --version || true

echo
echo "== Nodes =="
kubectl get nodes || true

echo
echo "== Pods all namespaces =="
kubectl get pods -A || true