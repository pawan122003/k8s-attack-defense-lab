#!/bin/bash
# Kubernetes Forensics Evidence Collection Tool
# Automatically collect evidence for post-breach investigation
# Usage: ./collect-evidence.sh [namespace] [pod-name]

set -e

NAMESPACE="${1:-default}"
POD_NAME="${2:-}"
EVIDENCE_DIR="./evidence/$(date +%Y%m%d_%H%M%S)"

echo "=== Kubernetes Forensics Evidence Collector ==="
echo ""
echo "[*] Creating evidence directory: $EVIDENCE_DIR"
mkdir -p "$EVIDENCE_DIR"

# If pod specified, focus on that pod
if [ -n "$POD_NAME" ]; then
  echo "[*] Collecting evidence for pod: $NAMESPACE/$POD_NAME"
  
  # Pod specification
  echo "[*] Collecting pod spec..."
  kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o yaml > "$EVIDENCE_DIR/pod-spec.yaml"
  kubectl describe pod "$POD_NAME" -n "$NAMESPACE" > "$EVIDENCE_DIR/pod-describe.txt"
  
  # Container logs
  echo "[*] Collecting container logs..."
  CONTAINERS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.containers[*].name}')
  for CONTAINER in $CONTAINERS; do
    kubectl logs "$POD_NAME" -n "$NAMESPACE" -c "$CONTAINER" --timestamps=true > \
      "$EVIDENCE_DIR/logs-${CONTAINER}.txt" 2>/dev/null || echo "Failed to get logs for $CONTAINER"
  done
  
  # Previous pod logs (if available)
  echo "[*] Collecting previous logs (if pod crashed)..."
  kubectl logs "$POD_NAME" -n "$NAMESPACE" --previous > \
    "$EVIDENCE_DIR/logs-previous.txt" 2>/dev/null || true
  
  # Environment variables
  echo "[*] Collecting environment variables..."
  kubectl exec "$POD_NAME" -n "$NAMESPACE" -- env > "$EVIDENCE_DIR/pod-env.txt" 2>/dev/null || true
  
  # Process listing
  echo "[*] Collecting running processes..."
  kubectl exec "$POD_NAME" -n "$NAMESPACE" -- ps aux > "$EVIDENCE_DIR/pod-processes.txt" 2>/dev/null || true
  
  # Network connections
  echo "[*] Collecting network state..."
  kubectl exec "$POD_NAME" -n "$NAMESPACE" -- netstat -tpn > "$EVIDENCE_DIR/pod-netstat.txt" 2>/dev/null || \
  kubectl exec "$POD_NAME" -n "$NAMESPACE" -- ss -tpn > "$EVIDENCE_DIR/pod-ss.txt" 2>/dev/null || true
  
  # Mounted volumes
  echo "[*] Collecting volume information..."
  kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.volumes}' | \
    jq . > "$EVIDENCE_DIR/pod-volumes.json" 2>/dev/null || true
  
fi

# Namespace-wide collection
echo ""
echo "[*] Collecting namespace-wide evidence..."

# All pods
echo "[*] Listing all pods..."
kubectl get pods -n "$NAMESPACE" -o wide > "$EVIDENCE_DIR/pods-list.txt"
kubectl get pods -n "$NAMESPACE" -o json > "$EVIDENCE_DIR/pods-all.json"

# All events
echo "[*] Collecting events..."
kubectl get events -n "$NAMESPACE" -o wide > "$EVIDENCE_DIR/events-list.txt"
kubectl get events -n "$NAMESPACE" -o json > "$EVIDENCE_DIR/events-all.json"

# RBAC configuration
echo "[*] Collecting RBAC..."
kubectl get roles -n "$NAMESPACE" -o yaml > "$EVIDENCE_DIR/roles.yaml"
kubectl get rolebindings -n "$NAMESPACE" -o yaml > "$EVIDENCE_DIR/rolebindings.yaml"
kubectl get serviceaccounts -n "$NAMESPACE" -o yaml > "$EVIDENCE_DIR/serviceaccounts.yaml"

# ConfigMaps and Secrets (sanitized)
echo "[*] Collecting ConfigMaps..."
kubectl get configmaps -n "$NAMESPACE" -o yaml > "$EVIDENCE_DIR/configmaps.yaml"

echo "[*] Collecting Secrets (keys only, not values)..."
kubectl get secrets -n "$NAMESPACE" -o json | \
  jq '.items[] | {name: .metadata.name, keys: .data | keys}' > "$EVIDENCE_DIR/secrets-metadata.json"

# Cluster-level information
echo ""
echo "[*] Collecting cluster-level evidence..."

# Nodes
echo "[*] Collecting node information..."
kubectl get nodes -o yaml > "$EVIDENCE_DIR/nodes.yaml"
kubectl top nodes > "$EVIDENCE_DIR/nodes-metrics.txt" 2>/dev/null || true

# Cluster role bindings
echo "[*] Collecting cluster-level RBAC..."
kubectl get clusterroles -o yaml > "$EVIDENCE_DIR/clusterroles.yaml"
kubectl get clusterrolebindings -o yaml > "$EVIDENCE_DIR/clusterrolebindings.yaml"

# Webhooks
echo "[*] Collecting admission webhooks..."
kubectl get validatingwebhookconfigurations -o yaml > "$EVIDENCE_DIR/validating-webhooks.yaml" 2>/dev/null || true
kubectl get mutatingwebhookconfigurations -o yaml > "$EVIDENCE_DIR/mutating-webhooks.yaml" 2>/dev/null || true

# System pods
echo "[*] Collecting system pods..."
kubectl get pods -n kube-system -o yaml > "$EVIDENCE_DIR/kube-system-pods.yaml"

# API audit logs (if accessible)
echo ""
echo "[*] Collecting API audit logs (if running on control plane)..."
if ls /var/log/audit/audit.log 2>/dev/null; then
  cp /var/log/audit/audit.log "$EVIDENCE_DIR/audit.log"
  tail -100 /var/log/audit/audit.log > "$EVIDENCE_DIR/audit-recent.log"
else
  echo "[!] Audit logs not accessible from this pod"
fi

# API server logs
echo "[*] Collecting control plane component logs..."
for COMPONENT in kube-apiserver controller-manager scheduler; do
  kubectl logs -n kube-system -l component=$COMPONENT --tail=100 > \
    "$EVIDENCE_DIR/kube-system-${COMPONENT}.log" 2>/dev/null || true
done

# Generate evidence summary
echo ""
echo "[*] Generating evidence summary..."

cat > "$EVIDENCE_DIR/EVIDENCE_MANIFEST.txt" <<EOF
Kubernetes Forensics Evidence Collection
========================================
Collection Date: $(date)
Namespace: $NAMESPACE
Pod: $POD_NAME

Evidence Collected:
===================

1. Pod-level Evidence:
   - Pod specification and describe output
   - Container logs and previous logs
   - Environment variables
   - Running processes
   - Network state (connections)
   - Mounted volumes information

2. Namespace-wide Evidence:
   - Pod listings
   - Event stream
   - RBAC configuration
   - ConfigMaps
   - Secret metadata (keys only)

3. Cluster-level Evidence:
   - Node information and metrics
   - Cluster role bindings
   - Admission webhooks
   - System component logs
   - Kubernetes API audit logs

4. Timeline Reconstruction:
   - Pod creation timestamp
   - Container start time
   - Event timeline
   - Log timestamps

Analysis Tips:
==============

1. Check pod-spec.yaml for:
   - Suspicious environment variables
   - Unexpected volume mounts (hostPath, docker.sock)
   - Elevated security context (privileged, runAsUser:0)
   - Image source (unexpected registry)
   - Service account permissions

2. Check logs for:
   - Unusual process execution
   - Network connections to external IPs
   - Error messages indicating attacks
   - Time correlation with events

3. Check events for:
   - Pod lifecycle (create → waiting → running → error)
   - Network policy violations
   - Resource constraints (OOMKilled, Evicted)
   - Restarts and reasons

4. Check RBAC for:
   - Service account permissions
   - Unexpected role bindings
   - Cluster admin access

5. Cross-reference with:
   - Audit logs for API calls from pod
   - Other pod logs for lateral movement
   - Node metrics for resource anomalies

EOF

echo ""
echo "[+] Evidence collection complete!"
echo "[+] Evidence directory: $EVIDENCE_DIR"
echo "[+] Total files: $(find $EVIDENCE_DIR -type f | wc -l)"
echo "[+] Total size: $(du -sh $EVIDENCE_DIR | cut -f1)"

echo ""
echo "Next steps:"
echo "1. Review EVIDENCE_MANIFEST.txt for analysis tips"
echo "2. Examine pod-spec.yaml for suspicious configuration"
echo "3. Check logs-*.txt for malicious activity"
echo "4. Cross-reference audit.log with attack timeline"
echo "5. Document findings for incident report"
