#!/bin/bash
set -e
echo "Applying RBAC misuse attack..."
kubectl apply -f attacks/rbac-misuse/overprivileged-sa.yaml
echo "Deploying malicious pod..."
kubectl apply -f attacks/rbac-misuse/malicious-pod.yaml
echo "Running secret exfiltration attack..."
kubectl apply -f attacks/secrets-exfil/secret-stealer.yaml
echo "Running hostPath escape attack..."
kubectl apply -f attacks/hostpath-escape/host-mounter.yaml
