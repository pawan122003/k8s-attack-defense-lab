# Kubernetes Defense Strategies

## RBAC Hardening
Apply least-privileged roles, remove cluster-admin bindings from service accounts.

## Network Policies
Default-deny, restrict inter-pod communication.

## Pod Security Standards
Label enforcement, privilege drops, hostPath restrictions.

## Admission Policies
Kyverno/OPA to validate pod security context, resource limits, forbidden mounts.
