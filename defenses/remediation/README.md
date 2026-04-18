# Automated Remediation System

This directory contains automated response mechanisms that activate when security incidents are detected.

## Components

### 1. Quarantine Webhook (`quarantine-webhook.yaml`)

**Purpose**: Automatically isolates compromised pods when attacks are detected.

**How it works**:
- MutatingAdmissionWebhook monitors pod creation/updates
- When a pod is labeled `security.kubernetes.io/quarantined=true`, it:
  - Adds network isolation (applies `quarantine-deny-all` NetworkPolicy)
  - Adds quarantine metadata (timestamp, reason)
  - Prevents further pod modifications

**Deployment**:
```bash
kubectl apply -f defenses/remediation/quarantine-webhook.yaml
```

**Triggering Quarantine**:
```bash
# Manual quarantine (for testing)
kubectl label pod malicious-pod security.kubernetes.io/quarantined=true
kubectl annotate pod malicious-pod security.kubernetes.io/quarantine-reason="Detected privilege escalation"

# Automatic quarantine (via Falco rules)
# Falco rules can automatically label pods when attacks are detected
```

### 2. Forensics Preservation (`forensics-preservation.yaml`)

**Purpose**: Automatically collects and preserves evidence when pods are quarantined.

**Evidence Collected**:
- Pod specification (YAML)
- Current container logs
- Previous container logs (if crash occurred)
- Related Kubernetes events
- Environment variables
- Volume mounts
- Network connections (if available)

**Storage**:
- Evidence stored in `forensics-evidence` namespace as ConfigMaps
- Automatic cleanup after 7 days (configurable)
- Evidence format: `forensics-{namespace}-{pod}-{type}`

**Deployment**:
```bash
kubectl apply -f defenses/remediation/forensics-preservation.yaml
```

**Viewing Evidence**:
```bash
# List all evidence
kubectl get configmaps -n forensics-evidence

# View pod specification
kubectl get configmap forensics-default-malicious-pod-spec -n forensics-evidence -o yaml

# View logs
kubectl get configmap forensics-default-malicious-pod-logs -n forensics-evidence -o jsonpath='{.data.current-logs\.txt}' | base64 -d
```

### 3. Incident Escalation (`incident-escalation.yaml`)

**Purpose**: Sends alerts and notifications when security incidents occur.

**Alert Channels**:
- **Slack**: Real-time notifications to security channel
- **Email**: Detailed alerts to security team
- **PagerDuty**: Critical alerts for on-call response

**Alert Types**:
- **Critical**: Privilege escalation, cluster-admin access
- **High**: Data exfiltration, secret access
- **Medium**: Other security events

**Configuration**:
```bash
# Create secrets for alert channels
kubectl create secret generic alert-secrets \
  --from-literal=slack-webhook-url='https://hooks.slack.com/services/...' \
  --from-literal=pagerduty-routing-key='your-routing-key' \
  -n security-remediation
```

## Integration with Detection

### Falco Integration

Falco rules can automatically trigger remediation:

```yaml
# Example Falco rule that triggers quarantine
- rule: Privilege Escalation Detected
  desc: Detect privilege escalation attempts
  condition: >
    spawned_process and container
    and proc.name = "sudo" or proc.name = "su"
  output: >
    Privilege escalation attempt detected (user=%user.name command=%proc.cmdline)
  priority: CRITICAL
  tags: [privilege-escalation]
  # Custom action to quarantine pod
  action: quarantine
```

### Manual Triggering

For testing or manual response:

```bash
# Quarantine a suspicious pod
kubectl label pod suspicious-pod security.kubernetes.io/quarantined=true
kubectl annotate pod suspicious-pod security.kubernetes.io/quarantine-reason="Manual investigation"

# Check if evidence was collected
kubectl get configmaps -n forensics-evidence | grep suspicious-pod
```

## Monitoring Remediation

### Check System Status

```bash
# Check remediation components
kubectl get pods -n security-remediation

# Check quarantined pods
kubectl get pods --all-namespaces -l security.kubernetes.io/quarantined=true

# Check collected evidence
kubectl get configmaps -n forensics-evidence

# Check security events
kubectl get events --all-namespaces --field-selector reason=SecurityAlert
```

### Logs

```bash
# Webhook logs
kubectl logs -n security-remediation deployment/remediation-webhook

# Forensics collector logs
kubectl logs -n security-remediation deployment/forensics-collector

# Alert manager logs
kubectl logs -n security-remediation deployment/alert-manager
```

## Security Considerations

### RBAC

The remediation system runs with minimal privileges:
- Can only modify pods in monitored namespaces
- Cannot delete or modify cluster-critical resources
- Service account has read-only access to most resources

### Network Security

- Webhook service runs in isolated namespace
- TLS encryption for webhook communications
- Network policies prevent unauthorized access

### Alert Security

- Webhook URLs stored as Kubernetes secrets
- No sensitive data in alert messages
- Rate limiting prevents alert spam

## Troubleshooting

### Webhook Not Triggering

```bash
# Check webhook configuration
kubectl get mutatingwebhookconfigurations

# Check webhook pod logs
kubectl logs -n security-remediation deployment/remediation-webhook

# Verify TLS certificates
kubectl get secret remediation-webhook-tls -n security-remediation
```

### Evidence Not Collected

```bash
# Check forensics collector status
kubectl get pods -n security-remediation -l app=forensics-collector

# Check collector logs
kubectl logs -n security-remediation deployment/forensics-collector

# Verify namespace permissions
kubectl auth can-i create configmap -n forensics-evidence --as=system:serviceaccount:security-remediation:remediation-webhook-sa
```

### Alerts Not Sending

```bash
# Check alert secrets
kubectl get secrets -n security-remediation

# Check alert manager logs
kubectl logs -n security-remediation deployment/alert-manager

# Test webhook manually
curl -X POST -H 'Content-type: application/json' --data '{"text":"Test alert"}' $SLACK_WEBHOOK_URL
```

## Deployment Order

1. **Deploy remediation namespace and RBAC**:
   ```bash
   kubectl apply -f defenses/remediation/quarantine-webhook.yaml
   ```

2. **Deploy forensics preservation**:
   ```bash
   kubectl apply -f defenses/remediation/forensics-preservation.yaml
   ```

3. **Deploy incident escalation**:
   ```bash
   kubectl apply -f defenses/remediation/incident-escalation.yaml
   ```

4. **Configure alert channels** (optional):
   ```bash
   kubectl create secret generic alert-secrets -n security-remediation --from-literal=slack-webhook-url='...'
   ```

## Testing

### Test Quarantine

```bash
# Create a test pod
kubectl run test-pod --image=busybox -- sleep 3600

# Quarantine it
kubectl label pod test-pod security.kubernetes.io/quarantined=true

# Verify quarantine (should have deny-all network policy applied)
kubectl get networkpolicies -n default
```

### Test Forensics

```bash
# Check evidence collection
kubectl get configmaps -n forensics-evidence | grep test-pod
```

### Test Alerts

```bash
# Create a security event
kubectl create event --namespace default --involved-object-kind Pod --involved-object-name test-pod security-alert --reason SecurityAlert --message "Test security incident" --type Warning

# Check alert manager logs
kubectl logs -n security-remediation deployment/alert-manager
```