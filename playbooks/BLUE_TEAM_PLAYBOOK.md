# BLUE TEAM PLAYBOOK

## K8s Attack-Defense Lab - Defensive Exercises

**Version:** 1.0  
**Last Updated:** April 10, 2026  
**Focus:** Detection, Response, Hardening

---

## Table of Contents

1. [Introduction](#introduction)
2. [Preparation](#preparation)
3. [Defense Strategies](#defense-strategies)
4. [Monitoring & Detection](#monitoring--detection)
5. [Incident Response](#incident-response)
6. [Hardening Guide](#hardening-guide)
7. [Scoring System](#scoring-system)

---

## Introduction

This playbook provides defensive security exercises for the K8s Attack-Defense Lab. Blue teamers will implement security controls, monitor for threats, and respond to incidents.

### Objectives

- **Implement Defenses**: Deploy comprehensive security controls
- **Monitor Threats**: Set up effective detection and alerting
- **Respond to Incidents**: Practice incident response procedures
- **Measure Effectiveness**: Validate defense effectiveness

### Defense Layers

```
┌─────────────────────────────────────┐
│ 7. Incident Response               │
├─────────────────────────────────────┤
│ 6. Runtime Security (Falco)        │
├─────────────────────────────────────┤
│ 5. Admission Control (Kyverno/OPA) │
├─────────────────────────────────────┤
│ 4. Network Security (NetworkPolicy)│
├─────────────────────────────────────┤
│ 3. Pod Security (PSS/RBAC)         │
├─────────────────────────────────────┤
│ 2. Image Security (Scanning/Signing)│
├─────────────────────────────────────┤
│ 1. Infrastructure Security         │
└─────────────────────────────────────┘
```

---

## Preparation

### Environment Setup

1. **Deploy Defense Infrastructure**:
   ```bash
   # Deploy admission controllers
   kubectl apply -f policies/kyverno/
   kubectl apply -f policies/opa/

   # Deploy network policies
   kubectl apply -f defenses/networkpolicies/

   # Deploy pod security
   kubectl apply -f defenses/podsecurity/

   # Deploy monitoring
   kubectl apply -f monitors/falco/advanced-rules.yaml
   kubectl apply -f monitors/audit-logs/audit-policy.yaml

   # Deploy remediation
   kubectl apply -f defenses/remediation/
   ```

2. **Verify Defenses**:
   ```bash
   # Run validation
   ./tests/validators/validate-defenses.sh
   ```

3. **Set Up Monitoring Dashboards**:
   ```bash
   # Start monitoring scripts
   ./monitors/audit-logs/analyze-audit.sh /var/log/audit/audit.log &
   kubectl logs -f -n falco daemonset/falco &
   ```

### Tools Required

- **kubectl**: Cluster management
- **kubectx/kubens**: Context switching
- **stern**: Multi-pod log tailing
- **kubeaudit**: Security auditing
- **Custom Scripts**: In `monitors/` and `tests/`

---

## Defense Strategies

### 1. Infrastructure Security

#### Secure Cluster Setup

**Objective:** Establish secure cluster foundation

**Actions:**
1. Enable audit logging
2. Configure RBAC with least privilege
3. Set up network policies
4. Enable Pod Security Standards

**Commands:**
```bash
# Enable audit logging
kubectl apply -f monitors/audit-logs/audit-policy.yaml

# Set PSS enforcement
kubectl label namespace default pod-security.kubernetes.io/enforce=restricted

# Apply default deny network policy
kubectl apply -f defenses/networkpolicies/default-deny.yaml
```

#### Node Security

**Objective:** Harden worker nodes

**Checklist:**
- ✅ Disable privileged containers
- ✅ Use read-only root filesystem
- ✅ Drop unnecessary capabilities
- ✅ Run as non-root user
- ✅ Use security contexts

### 2. Image Security

#### Image Scanning & Signing

**Objective:** Prevent malicious container deployment

**Implementation:**
```bash
# Enable image verification
kubectl apply -f policies/kyverno/require-image-signature.yaml

# Block latest tags
kubectl apply -f policies/kyverno/disallow-latest-tag.yaml

# Require security scanning
kubectl apply -f policies/kyverno/require-image-scan.yaml
```

#### Supply Chain Protection

**Objective:** Protect against supply chain attacks

**Controls:**
- Image signing verification
- SBOM (Software Bill of Materials) checks
- Vulnerability scanning
- Registry access controls

### 3. Pod Security

#### Pod Security Standards

**Objective:** Enforce pod security best practices

**Profiles:**
- **Privileged**: Unrestricted (not recommended)
- **Baseline**: Minimal restrictions
- **Restricted**: Highly secure (recommended)

**Implementation:**
```bash
# Apply restricted PSS
kubectl label namespace production pod-security.kubernetes.io/enforce=restricted

# Verify enforcement
kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{","}{.metadata.name}{","}{.status.phase}{"\n"}{end}' | \
grep -v "Running"
```

#### RBAC Hardening

**Objective:** Implement least privilege access

**Best Practices:**
- Use dedicated service accounts
- Apply principle of least privilege
- Regular permission reviews
- Automate RBAC management

### 4. Network Security

#### Network Policies

**Objective:** Control pod-to-pod communication

**Implementation:**
```bash
# Default deny all
kubectl apply -f defenses/networkpolicies/default-deny.yaml

# Allow specific traffic
kubectl apply -f defenses/networkpolicies/allow-frontend-to-backend.yaml

# Test policies
kubectl run test-pod --image=busybox --rm -it -- wget --timeout=5 backend-service
```

#### Service Mesh Security

**Objective:** Encrypt service-to-service communication

**Considerations:**
- Mutual TLS (mTLS)
- Traffic encryption
- Service identity
- Authorization policies

### 5. Admission Control

#### Kyverno Policies

**Objective:** Validate and mutate resources

**Key Policies:**
```bash
# Disallow host path mounts
kubectl apply -f policies/kyverno/disallow-host-path.yaml

# Require security labels
kubectl apply -f policies/kyverno/require-security-labels.yaml

# Drop dangerous capabilities
kubectl apply -f policies/kyverno/require-drop-capabilities.yaml
```

#### OPA Gatekeeper

**Objective:** Policy-based admission control

**Implementation:**
```bash
# Deploy constraint templates
kubectl apply -f policies/opa/

# Check violations
kubectl get constraintviolations
```

### 6. Runtime Security

#### Falco Deployment

**Objective:** Runtime threat detection

**Rules Categories:**
- Privilege escalation detection
- File access monitoring
- Network anomaly detection
- Container drift detection

**Monitoring:**
```bash
# Watch Falco alerts
kubectl logs -f -n falco daemonset/falco

# Check alert patterns
kubectl logs -n falco daemonset/falco | grep -i "warning\|error\|critical"
```

#### Audit Logging

**Objective:** Comprehensive security event logging

**Configuration:**
```bash
# Enable audit policy
kubectl apply -f monitors/audit-logs/audit-policy.yaml

# Analyze logs
./monitors/audit-logs/analyze-audit.sh /var/log/audit/audit.log
```

### 7. Incident Response

#### Automated Remediation

**Objective:** Immediate threat containment

**Components:**
- Pod quarantine
- Evidence collection
- Alert escalation

**Deployment:**
```bash
# Deploy remediation system
kubectl apply -f defenses/remediation/

# Test quarantine
kubectl label pod suspicious-pod security.kubernetes.io/quarantined=true
```

#### Manual Response

**Objective:** Human-guided incident handling

**Process:**
1. **Detection**: Alert triggers
2. **Assessment**: Evaluate impact
3. **Containment**: Isolate affected systems
4. **Eradication**: Remove threats
5. **Recovery**: Restore systems
6. **Lessons Learned**: Update defenses

---

## Monitoring & Detection

### Alert Triage

#### Falco Alerts

**Common Alerts:**
```
- Privilege escalation attempts
- Suspicious file access
- Unusual network connections
- Container drift
```

**Triage Process:**
```bash
# Get recent alerts
kubectl logs -n falco daemonset/falco --since=1h | grep -i "warning\|error"

# Investigate pod
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

#### Audit Log Analysis

**Key Events to Monitor:**
- Secret access attempts
- RBAC changes
- Pod creation/deletion
- API server abuse

**Analysis:**
```bash
# Run audit analysis
./monitors/audit-logs/analyze-audit.sh /var/log/audit/audit.log

# Look for anomalies
grep "secrets" /var/log/audit/audit.log | tail -20
```

### Threat Hunting

#### Proactive Detection

**Hunting Queries:**
```bash
# Find privileged pods
kubectl get pods --all-namespaces -o jsonpath='{range .items[?(@.spec.securityContext.privileged)]}{.metadata.namespace}{"/"}{.metadata.name}{"\n"}{end}'

# Check service account usage
kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"/"}{.metadata.name}{":"}{.spec.serviceAccountName}{"\n"}{end}' | grep "default"

# Find host path mounts
kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.spec.volumes[?(@.hostPath)].hostPath.path}{"\n"}{end}'
```

#### Anomaly Detection

**Indicators of Compromise:**
- Unexpected privileged containers
- Unusual service account usage
- Suspicious network connections
- File integrity changes

---

## Incident Response

### Response Playbook

#### Phase 1: Detection & Assessment

**Actions:**
1. Acknowledge alert
2. Gather initial information
3. Assess impact and scope
4. Determine incident severity

**Commands:**
```bash
# Get pod details
kubectl describe pod <compromised-pod>

# Check related events
kubectl get events --field-selector involvedObject.name=<pod-name>

# Review audit logs
./monitors/audit-logs/analyze-audit.sh /var/log/audit/audit.log | grep <pod-name>
```

#### Phase 2: Containment

**Actions:**
1. Quarantine affected pods
2. Block malicious traffic
3. Disable compromised accounts
4. Preserve evidence

**Commands:**
```bash
# Quarantine pod
kubectl label pod <compromised-pod> security.kubernetes.io/quarantined=true

# Collect evidence
./monitors/forensics/collect-evidence.sh <namespace> <pod-name>

# Block network traffic
kubectl apply -f defenses/networkpolicies/emergency-block.yaml
```

#### Phase 3: Eradication

**Actions:**
1. Remove malicious components
2. Clean affected systems
3. Patch vulnerabilities
4. Update defenses

**Commands:**
```bash
# Delete compromised resources
kubectl delete pod <compromised-pod>

# Update images
kubectl set image deployment/<deployment> <container>=<safe-image>:<tag>

# Rotate credentials
kubectl create token <service-account> # For new token
```

#### Phase 4: Recovery

**Actions:**
1. Restore systems from clean backups
2. Validate system integrity
3. Monitor for re-infection
4. Resume normal operations

#### Phase 5: Lessons Learned

**Actions:**
1. Document incident timeline
2. Identify root cause
3. Update prevention measures
4. Improve response procedures

---

## Hardening Guide

### Automated Hardening

**Quick Security Setup:**
```bash
# Run comprehensive hardening
./scripts/harden-cluster.sh

# Validate security posture
./tests/validators/validate-defenses.sh
```

### Manual Hardening Checklist

#### Critical (Must Do)
- [ ] Enable Pod Security Standards (Restricted)
- [ ] Deploy network policies (default deny)
- [ ] Enable audit logging
- [ ] Deploy Falco with custom rules
- [ ] Implement RBAC least privilege

#### Important (Should Do)
- [ ] Enable image signing verification
- [ ] Deploy admission controllers (Kyverno/OPA)
- [ ] Set up automated remediation
- [ ] Configure secrets management
- [ ] Enable service mesh security

#### Optional (Nice to Have)
- [ ] Implement zero-trust networking
- [ ] Set up security monitoring dashboard
- [ ] Enable automated compliance checks
- [ ] Implement secrets rotation
- [ ] Set up backup and disaster recovery

### Security Benchmarks

#### CIS Kubernetes Benchmark

**Key Controls:**
- API server security configuration
- RBAC implementation
- Network policies
- Pod security
- Audit logging

**Validation:**
```bash
# Run CIS checks
kube-bench run --targets master,node,etcd,policies
```

#### NSA/CISA Kubernetes Hardening Guide

**Priority Actions:**
1. Use minimal base images
2. Implement network segmentation
3. Enable audit logging
4. Use RBAC for authorization
5. Regularly update and patch

---

## Scoring System

### Defense Effectiveness Score

**Components:**
- **Prevention (40%)**: Controls that block attacks
- **Detection (30%)**: Ability to identify threats
- **Response (20%)**: Incident handling effectiveness
- **Hardening (10%)**: Overall security posture

**Scoring Formula:**
```
Score = (Prevention × 0.4) + (Detection × 0.3) + (Response × 0.2) + (Hardening × 0.1)
```

### Test Results Integration

**Automated Scoring:**
```bash
# Run full test suite
./tests/test-runner.sh

# Calculate defense score
./tests/calculate-defense-score.sh
```

### Improvement Tracking

**Metrics to Track:**
- Mean time to detect (MTTD)
- Mean time to respond (MTTR)
- False positive rate
- Attack success rate
- Recovery time

### Leaderboard

Compare defense effectiveness across different configurations and team members.

---

## Advanced Topics

### Threat Modeling

**STRIDE Framework:**
- **Spoofing**: Authentication attacks
- **Tampering**: Data modification
- **Repudiation**: Audit log attacks
- **Information Disclosure**: Secrets exposure
- **Denial of Service**: Resource exhaustion
- **Elevation of Privilege**: Permission escalation

### Zero Trust Architecture

**Principles:**
1. Never trust, always verify
2. Assume breach mentality
3. Use least privilege access
4. Micro-segmentation
5. Continuous monitoring

### DevSecOps Integration

**Security in CI/CD:**
- Automated security scanning
- Policy-as-code validation
- Infrastructure-as-code security
- Continuous compliance monitoring

---

## Troubleshooting

### Common Issues

**Network Policies Not Working:**
```bash
# Check policy syntax
kubectl describe networkpolicy <policy-name>

# Verify pod labels
kubectl get pods --show-labels
```

**Falco Not Detecting:**
```bash
# Check Falco status
kubectl get pods -n falco

# Verify rules loaded
kubectl exec -n falco daemonset/falco -- falco --list
```

**Admission Controllers Blocking:**
```bash
# Check policy violations
kubectl get policyreports -o wide

# Review Kyverno logs
kubectl logs -n kyverno deployment/kyverno
```

### Getting Help

1. Check policy documentation
2. Review Falco rule syntax
3. Use kubectl debugging
4. Consult security best practices

---

## Next Steps

1. **Complete Basic Defenses**
2. **Implement Advanced Controls**
3. **Practice Incident Response**
4. **Participate in Red Team Exercises**
5. **Contribute to Security Improvements**

---

*This playbook evolves with new threats and defense techniques. Regular updates recommended.*