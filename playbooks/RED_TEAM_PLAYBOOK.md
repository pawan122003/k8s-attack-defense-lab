# RED TEAM PLAYBOOK

## K8s Attack-Defense Lab - Offensive Exercises

**Version:** 1.0  
**Last Updated:** April 10, 2026  
**Difficulty Levels:** Beginner, Intermediate, Advanced, Expert

---

## Table of Contents

1. [Introduction](#introduction)
2. [Preparation](#preparation)
3. [Attack Categories](#attack-categories)
4. [Scenario Walkthroughs](#scenario-walkthroughs)
5. [Scoring System](#scoring-system)
6. [Rules of Engagement](#rules-of-engagement)

---

## Introduction

This playbook provides offensive security exercises for the K8s Attack-Defense Lab. Red teamers will simulate real-world attacks against Kubernetes clusters while blue teamers implement and test defenses.

### Objectives

- **Learn Attack Techniques**: Understand common K8s attack vectors
- **Test Defenses**: Validate security controls effectiveness
- **Improve Skills**: Gain hands-on experience with offensive tools
- **Measure Success**: Use scoring system to track progress

### Difficulty Levels

| Level | Description | Prerequisites |
|-------|-------------|---------------|
| 🟢 **Beginner** | Basic attacks, clear indicators | Basic kubectl knowledge |
| 🟡 **Intermediate** | Stealth techniques, evasion | Understanding of K8s concepts |
| 🟠 **Advanced** | Complex chains, custom tooling | Experience with containers/security |
| 🔴 **Expert** | Zero-day style, novel techniques | Deep K8s internals knowledge |

---

## Preparation

### Environment Setup

1. **Deploy Lab Infrastructure**:
   ```bash
   # Deploy all attack scenarios
   kubectl apply -f attacks/supply-chain/
   kubectl apply -f attacks/lateral-movement/
   kubectl apply -f attacks/persistence/
   kubectl apply -f attacks/dos/

   # Deploy monitoring
   kubectl apply -f monitors/falco/advanced-rules.yaml
   kubectl apply -f monitors/audit-logs/audit-policy.yaml
   ```

2. **Verify Environment**:
   ```bash
   # Check cluster status
   kubectl get nodes
   kubectl get pods --all-namespaces

   # Verify Falco is running
   kubectl get pods -n falco
   ```

3. **Set Up Monitoring**:
   ```bash
   # Watch Falco alerts
   kubectl logs -f -n falco daemonset/falco

   # Monitor audit logs
   ./monitors/audit-logs/analyze-audit.sh /var/log/audit/audit.log
   ```

### Tools Required

- **kubectl**: Cluster interaction
- **kubelet**: Node-level access (if available)
- **curl/wget**: Network testing
- **nslookup/dig**: DNS investigation
- **Custom Scripts**: In `scripts/` directory

---

## Attack Categories

### 1. Supply Chain Attacks

**Goal**: Compromise applications through trusted supply chain

#### Scenario 1.1: Poisoned Container Image 🟢 Beginner
**File:** `attacks/supply-chain/poisoned-image.yaml`

**Objective:** Deploy backdoored container that establishes C2

**Steps:**
1. Deploy the poisoned application
2. Verify reverse shell connection
3. Attempt data exfiltration

**Commands:**
```bash
kubectl apply -f attacks/supply-chain/poisoned-image.yaml
kubectl logs -f deployment/poisoned-app
```

**Success Criteria:**
- Reverse shell established
- C2 communication successful
- Data exfiltration completed

**Detection Points:**
- Image from untrusted registry
- Unusual network connections
- Suspicious process execution

#### Scenario 1.2: Webhook Mutator Bypass 🟡 Intermediate
**File:** `attacks/supply-chain/webhook-mutator.yaml`

**Objective:** Bypass admission webhooks to inject malicious sidecars

**Steps:**
1. Deploy webhook fuzzer
2. Attempt JSON patch injection
3. Escalate privileges via sidecar

**Commands:**
```bash
kubectl apply -f attacks/supply-chain/webhook-mutator.yaml
kubectl logs -f deployment/webhook-fuzzer
```

**Success Criteria:**
- Sidecar injection successful
- Privilege escalation achieved
- Persistence established

#### Scenario 1.3: Image Tag Confusion 🟠 Advanced
**File:** `attacks/supply-chain/tag-confusion.yaml`

**Objective:** Exploit mutable image tags for supply chain attack

**Steps:**
1. Deploy vulnerable application (using `:latest`)
2. Push malicious image with same tag
3. Trigger rolling update
4. Verify compromise

**Commands:**
```bash
kubectl apply -f attacks/supply-chain/tag-confusion.yaml
# Wait for deployment
kubectl get pods -l app=vulnerable-app
kubectl logs -f deployment/vulnerable-app
```

### 2. Lateral Movement Attacks

**Goal:** Move through cluster gaining higher privileges

#### Scenario 2.1: Service Account Token Theft 🟢 Beginner
**File:** `attacks/lateral-movement/serviceaccount-theft.yaml`

**Objective:** Steal and reuse service account tokens

**Steps:**
1. Access pod with mounted token
2. Extract token from filesystem
3. Use token to access other resources
4. Escalate to cluster-admin

**Commands:**
```bash
kubectl apply -f attacks/lateral-movement/serviceaccount-theft.yaml
kubectl exec -it deployment/token-stealer -- /bin/bash
# Inside pod: cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

#### Scenario 2.2: Kubelet API Abuse 🟡 Intermediate
**File:** `attacks/lateral-movement/kubelet-api.yaml`

**Objective:** Access kubelet API for pod data extraction

**Steps:**
1. Connect to localhost:10250
2. Enumerate running pods
3. Extract logs and secrets
4. Move to other nodes

**Commands:**
```bash
kubectl apply -f attacks/lateral-movement/kubelet-api.yaml
kubectl exec -it deployment/kubelet-abuser -- /bin/bash
# Inside pod: curl -k https://localhost:10250/pods
```

#### Scenario 2.3: DaemonSet Privilege Escalation 🟠 Advanced
**File:** `attacks/lateral-movement/daemonset-escalation.yaml`

**Objective:** Create privileged DaemonSet for cluster takeover

**Steps:**
1. Deploy DaemonSet with host access
2. Escalate to root on all nodes
3. Establish persistence
4. Cover tracks

**Commands:**
```bash
kubectl apply -f attacks/lateral-movement/daemonset-escalation.yaml
kubectl get daemonsets
kubectl logs -f daemonset/privileged-daemon
```

#### Scenario 2.4: etcd SSRF Exploitation 🔴 Expert
**File:** `attacks/lateral-movement/etcd-ssrf.yaml`

**Objective:** Access etcd via SSRF to steal all secrets

**Steps:**
1. Find SSRF vulnerability
2. Craft request to etcd endpoint
3. Extract cluster secrets
4. Use secrets for further attacks

### 3. Persistence Attacks

**Goal:** Maintain access despite defensive measures

#### Scenario 3.1: LD_PRELOAD Rootkit 🟡 Intermediate
**File:** `attacks/persistence/image-rootkit.yaml`

**Objective:** Hide processes and connections using LD_PRELOAD

**Steps:**
1. Deploy container with rootkit
2. Verify process hiding
3. Test connection masking
4. Establish C2 persistence

#### Scenario 3.2: Log Tampering 🟠 Advanced
**File:** `attacks/persistence/log-tampering.yaml`

**Objective:** Delete evidence from audit logs

**Steps:**
1. Gain access to logging system
2. Delete incriminating events
3. Modify timestamps
4. Verify evidence destruction

#### Scenario 3.3: CronJob Backdoor 🟡 Intermediate
**File:** `attacks/persistence/cronjob-backdoor.yaml`

**Objective:** Create scheduled reverse shells

**Steps:**
1. Deploy CronJob with shell payload
2. Verify scheduled execution
3. Test persistence across restarts
4. Clean up (or not)

#### Scenario 3.4: CNI Plugin Hijacking 🔴 Expert
**File:** `attacks/persistence/cni-interception.yaml`

**Objective:** Intercept all pod network traffic

**Steps:**
1. Modify CNI configuration
2. Deploy malicious CNI plugin
3. Capture network traffic
4. Maintain access

### 4. Denial of Service Attacks

**Goal:** Disrupt cluster availability

#### Scenario 4.1: API Server Flood 🟢 Beginner
**File:** `attacks/dos/api-server-watch-spam.yaml`

**Objective:** Exhaust API server connections

**Steps:**
1. Deploy multiple watchers
2. Monitor connection count
3. Verify API server impact
4. Test recovery

#### Scenario 4.2: Resource Starvation 🟢 Beginner
**File:** `attacks/dos/node-starvation.yaml`

**Objective:** Prevent pod scheduling

**Steps:**
1. Request excessive resources
2. Check pod scheduling status
3. Verify cluster impact
4. Test autoscaling response

#### Scenario 4.3: DNS Amplification 🟡 Intermediate
**File:** `attacks/dos/dns-amplification.yaml`

**Objective:** Overload CoreDNS service

**Steps:**
1. Generate DNS query flood
2. Monitor DNS resolution
3. Check CoreDNS performance
4. Verify service disruption

#### Scenario 4.4: PVC Exhaustion 🟡 Intermediate
**File:** `attacks/dos/pvc-full.yaml`

**Objective:** Fill persistent storage

**Steps:**
1. Write unlimited data to PVC
2. Monitor disk usage
3. Verify application impact
4. Test storage limits

---

## Scenario Walkthroughs

### Detailed Walkthrough: Poisoned Image Attack

**Time Estimate:** 15-20 minutes  
**Difficulty:** Beginner  
**Points:** 100

#### Step-by-Step Guide

1. **Reconnaissance**:
   ```bash
   # Check current deployments
   kubectl get deployments
   kubectl get pods
   ```

2. **Deploy Attack**:
   ```bash
   kubectl apply -f attacks/supply-chain/poisoned-image.yaml
   ```

3. **Monitor Deployment**:
   ```bash
   kubectl get pods -w
   kubectl logs -f deployment/poisoned-app
   ```

4. **Verify Success**:
   - Check for reverse shell connection
   - Look for C2 callbacks in logs
   - Verify data exfiltration

5. **Check Detection**:
   ```bash
   # Check Falco alerts
   kubectl logs -n falco daemonset/falco --tail=20

   # Check audit logs
   ./monitors/audit-logs/analyze-audit.sh /var/log/audit/audit.log
   ```

6. **Attempt Cleanup** (if desired):
   ```bash
   kubectl delete -f attacks/supply-chain/poisoned-image.yaml
   ```

#### Expected Outcomes

**Success Indicators:**
- ✅ Pod starts successfully
- ✅ Reverse shell established
- ✅ C2 communication observed
- ✅ Falco alerts triggered

**Detection Evasion Techniques:**
- Use legitimate-looking image names
- Encode payloads
- Slow down execution
- Use DNS tunneling for C2

---

## Scoring System

### Points Breakdown

| Category | Base Points | Difficulty Multiplier |
|----------|-------------|----------------------|
| Supply Chain | 100 | 1.0x - 2.0x |
| Lateral Movement | 150 | 1.2x - 2.5x |
| Persistence | 200 | 1.5x - 3.0x |
| DoS | 75 | 1.0x - 1.5x |

### Difficulty Multipliers

- **Beginner (x1.0)**: Direct attack, obvious indicators
- **Intermediate (x1.5)**: Some stealth, basic evasion
- **Advanced (x2.0)**: Complex techniques, good evasion
- **Expert (x3.0)**: Novel methods, zero detection

### Bonus Points

- **Stealth (+50)**: No alerts triggered
- **Cleanup (+25)**: Evidence removed
- **Chaining (+100)**: Multiple scenarios combined
- **Time Bonus**: < 5 min (+50), < 10 min (+25)

### Example Scoring

```
Poisoned Image (Beginner) + Stealth + Fast = 100 + 50 + 50 = 200 points
Service Account Theft (Intermediate) + Chaining = 150 × 1.5 + 100 = 325 points
```

### Leaderboard

Track scores across different attempts and compare with other red teamers.

---

## Rules of Engagement

### Ethical Guidelines

1. **Scope Limitation**: Only attack designated lab environment
2. **No Production Impact**: Never test on production clusters
3. **Responsible Disclosure**: Report findings appropriately
4. **Clean Up**: Remove attack artifacts after testing

### Safety Measures

1. **Isolated Environment**: Use dedicated lab cluster
2. **Resource Limits**: Set appropriate resource quotas
3. **Monitoring**: Enable comprehensive logging
4. **Backup**: Regular cluster backups

### Legal Compliance

- Only attack systems you own or have explicit permission to attack
- Follow your organization's red team policies
- Document all activities for compliance

---

## Advanced Techniques

### Chaining Attacks

Combine multiple scenarios for greater impact:

1. **Supply Chain → Lateral Movement**:
   - Poison image to gain initial access
   - Use compromised pod to steal service account
   - Escalate privileges via token

2. **Persistence → C2**:
   - Establish CronJob backdoor
   - Use for reliable C2 channel
   - Maintain access despite pod restarts

### Evasion Techniques

1. **Timing**: Slow down attacks to avoid rate limiting
2. **Encoding**: Base64 encode payloads and commands
3. **DNS Tunneling**: Use DNS for C2 communication
4. **Living off the Land**: Use existing cluster tools

### Custom Tool Development

Create specialized tools for complex attacks:

```bash
# Example: Custom token extractor
kubectl run token-extractor --image=busybox --rm -it -- \
  sh -c 'find /var/run/secrets -name token -exec cat {} \;'
```

---

## Troubleshooting

### Common Issues

**Pods Not Starting:**
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

**Attacks Not Working:**
- Check RBAC permissions
- Verify network connectivity
- Review pod security policies

**Detection Not Triggering:**
- Verify Falco rules are loaded
- Check audit policy configuration
- Test with known malicious activity

### Getting Help

1. Check scenario README files
2. Review Falco logs for errors
3. Use kubectl debugging commands
4. Consult Kubernetes documentation

---

## Next Steps

1. **Complete All Beginner Scenarios**
2. **Move to Intermediate Difficulty**
3. **Practice Chaining Techniques**
4. **Develop Custom Attack Tools**
5. **Participate in CTF Competitions**

---

*This playbook is continuously updated. Check for new scenarios and techniques.*