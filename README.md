# Kubernetes Attack & Defense Lab

![K8s Security](https://img.shields.io/badge/Kubernetes-Security-326CE5?logo=kubernetes)
![Security Scanning](https://img.shields.io/github/actions/workflow/status/pawan122003/k8s-attack-defense-lab/security.yml?label=Security%20Checks)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Kyverno](https://img.shields.io/badge/Kyverno-Policies-00B3FF)
![OPA](https://img.shields.io/badge/OPA-Rego-5EABA7)
![Falco](https://img.shields.io/badge/Falco-Runtime-00AEC7)
![Scenarios](https://img.shields.io/badge/Scenarios-15-blue)
![Difficulty](https://img.shields.io/badge/Difficulty-Beginner--Expert-orange)

> **Enterprise-grade Kubernetes security lab: 15 advanced attack scenarios, comprehensive detection, automated remediation, and red/blue team exercises**

## 🎯 Overview

This comprehensive lab simulates real-world Kubernetes security threats and defense strategies. Featuring 15 advanced attack scenarios across 4 categories, enterprise-grade monitoring with Falco, automated incident response, and detailed playbooks for both offensive and defensive exercises.

### What You'll Learn

- **🔴 Red Team**: Execute sophisticated attacks (supply chain, lateral movement, persistence, DoS)
- **🔵 Blue Team**: Implement defense-in-depth, monitor threats, respond to incidents
- **🛡️ Security Tools**: Kyverno, OPA, Falco, audit logging, automated remediation
- **📊 DevSecOps**: CI/CD security gates, policy-as-code, compliance automation

### Key Features

- **15 Attack Scenarios**: From basic privilege escalation to advanced CNI hijacking
- **36 Detection Rules**: Comprehensive Falco rules covering all attack types
- **Automated Remediation**: Pod quarantine, evidence collection, alert escalation
- **Scoring Dashboard**: Measure offensive/defensive effectiveness
- **Red/Blue Playbooks**: Detailed exercise guides with difficulty progression
- **Test Automation**: Validate attacks work and defenses block them

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  7. Incident Response     6. Runtime Security (Falco)      │
│  • Automated Quarantine   • 36 Detection Rules             │
│  • Evidence Collection    • Audit Logging                   │
│  • Alert Escalation       • Forensics Tools                 │
├─────────────────────────────────────────────────────────────┤
│  5. Admission Control     4. Network Security              │
│  • Kyverno Policies       • NetworkPolicies                 │
│  • OPA Gatekeeper         • Service Mesh                    │
│  • Policy-as-Code         • Zero Trust                      │
├─────────────────────────────────────────────────────────────┤
│  3. Pod Security          2. Image Security                │
│  • PSS Restricted         • Signature Verification          │
│  • RBAC Least Privilege   • Vulnerability Scanning          │
│  • Security Contexts      • SBOM Checks                     │
├─────────────────────────────────────────────────────────────┤
│  1. Infrastructure        │ Attack Scenarios (15)           │
│  • Kind Cluster           │ • Supply Chain (3)              │
│  • Security Hardening     │ • Lateral Movement (4)          │
│  • Audit Logging          │ • Persistence (4)               │
│                           │ • DoS (4)                       │
└───────────────────────────┴─────────────────────────────────┘
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                 CI/CD Security Pipeline                      │
├─────────────────────────────────────────────────────────────┤
│  kubeconform → kubescape → kube-linter → Kyverno → OPA     │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│              Kind Cluster (Local K8s)                        │
├─────────────────────────────────────────────────────────────┤
│  • Attack Scenarios      • Admission Policies               │
│  • Network Policies      • Falco Runtime Monitoring         │
│  • Pod Security          • RBAC Hardening                   │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
k8s-attack-defense-lab/
├── attacks/                    # 15 Attack Scenarios
│   ├── supply-chain/          # 3 scenarios (poisoned images, webhooks, tags)
│   │   ├── poisoned-image.yaml
│   │   ├── webhook-mutator.yaml
│   │   ├── tag-confusion.yaml
│   │   └── README.md
│   ├── lateral-movement/      # 4 scenarios (token theft, kubelet, daemonset, etcd)
│   │   ├── serviceaccount-theft.yaml
│   │   ├── kubelet-api.yaml
│   │   ├── daemonset-escalation.yaml
│   │   └── etcd-ssrf.yaml
│   ├── persistence/           # 4 scenarios (rootkit, log tampering, cronjob, CNI)
│   │   ├── image-rootkit.yaml
│   │   ├── log-tampering.yaml
│   │   ├── cronjob-backdoor.yaml
│   │   └── cni-interception.yaml
│   ├── dos/                   # 4 scenarios (API flood, starvation, DNS, PVC)
│   │   ├── api-server-watch-spam.yaml
│   │   ├── node-starvation.yaml
│   │   ├── dns-amplification.yaml
│   │   └── pvc-full.yaml
│   ├── rbac-misuse/           # Legacy: basic RBAC attacks
│   ├── secrets-exfil/         # Legacy: basic secrets exfil
│   └── hostpath-escape/       # Legacy: basic hostPath escape
├── defenses/                  # Defense Implementations
│   ├── remediation/           # Automated Response System
│   │   ├── quarantine-webhook.yaml
│   │   ├── forensics-preservation.yaml
│   │   ├── incident-escalation.yaml
│   │   └── README.md
│   ├── networkpolicies/       # Network Security
│   ├── podsecurity/           # Pod Security Standards
│   └── rbac/                  # RBAC Hardening
├── monitors/                  # Monitoring & Detection
│   ├── falco/                 # Runtime Security (27 rules)
│   │   └── advanced-rules.yaml
│   ├── audit-logs/            # Audit Logging
│   │   ├── audit-policy.yaml
│   │   └── analyze-audit.sh
│   ├── forensics/             # Evidence Collection
│   │   └── collect-evidence.sh
│   └── metrics/               # Performance Metrics
├── policies/                  # Policy as Code
│   ├── kyverno/               # Kyverno Policies
│   └── opa/                   # OPA Gatekeeper
├── tests/                     # Validation & Testing
│   ├── scenarios/             # Test Scripts
│   │   └── test-supply-chain-poisoned-image.sh
│   ├── validators/            # Defense Validation
│   │   └── validate-defenses.sh
│   └── test-runner.sh         # Test Orchestration
├── playbooks/                 # Exercise Guides
│   ├── RED_TEAM_PLAYBOOK.md   # Offensive Exercises
│   └── BLUE_TEAM_PLAYBOOK.md  # Defensive Exercises
├── dashboard/                 # Scoring & Reporting
│   └── generate-dashboard.sh  # Performance Dashboard
├── cluster/                   # Infrastructure
│   └── kind-config.yaml       # Kind Cluster Config
├── scripts/                   # Automation Scripts
│   ├── install_tools.sh       # Tool Installation
│   ├── run_attack_suite.sh    # Attack Execution
│   └── harden-cluster.sh      # Security Hardening
├── docs/                      # Documentation
│   ├── attacks.md             # Attack Documentation
│   ├── defenses.md            # Defense Guide
│   └── IMPLEMENTATION_SUMMARY.md
├── ctf/                       # Capture The Flag
│   └── challenges/            # CTF Challenges
├── .github/workflows/         # CI/CD Security
│   └── security.yml           # Security Pipeline
├── IMPLEMENTATION_SUMMARY.md  # Implementation Details

└── .devcontainer/             # Development Environment
    └── devcontainer.json      # Codespaces Configuration
```

## 🚀 Quick Start

### Prerequisites

- **Docker Desktop** or **Podman** (for Kind)
- **kubectl** >= 1.28
- **Kind** >= 0.20
- **Helm** >= 3.12
- **bash** (for scripts)

### One-Command Setup

```bash
# Clone and setup everything
git clone https://github.com/pawan122003/k8s-attack-defense-lab.git
cd k8s-attack-defense-lab

# Run complete setup (cluster + tools + defenses)
./scripts/setup-complete-lab.sh

# Verify installation
./dashboard/generate-dashboard.sh
```

### Manual Setup Steps

#### 1. Create Kind Cluster
```bash
kind create cluster --config cluster/kind-config.yaml --name attack-defense
```

#### 2. Install Security Tools
```bash
# Install all required tools
./scripts/install_tools.sh

# Verify tools
kubectl get nodes
helm version
```

#### 3. Deploy Defense Infrastructure
```bash
# Deploy admission controllers
kubectl apply -f policies/kyverno/
kubectl apply -f policies/opa/

# Deploy monitoring
kubectl apply -f monitors/falco/advanced-rules.yaml
kubectl apply -f monitors/audit-logs/audit-policy.yaml

# Deploy remediation
kubectl apply -f defenses/remediation/
```

#### 4. Deploy Attack Scenarios
```bash
# Deploy all attack scenarios
kubectl apply -f attacks/supply-chain/
kubectl apply -f attacks/lateral-movement/
kubectl apply -f attacks/persistence/
kubectl apply -f attacks/dos/
```

#### 5. Run Validation
```bash
# Validate defenses
./tests/validators/validate-defenses.sh

# Run test suite
./tests/test-runner.sh

# Generate dashboard
./dashboard/generate-dashboard.sh
```

## 🚢 Codespaces & Dev Container

Launch instantly with a pre-configured environment:

1. Click **Code** → **Codespaces** → **Create codespace**
2. Wait for container initialization (~2-3 minutes)
3. All tools are pre-installed: kubectl, kind, helm, kyverno CLI, kubescape

## ⚔️ Attack Scenarios (15 Total)

### 🟢 Beginner Level

#### 1. Supply Chain - Poisoned Image
**File:** `attacks/supply-chain/poisoned-image.yaml`
```bash
kubectl apply -f attacks/supply-chain/poisoned-image.yaml
kubectl logs -f deployment/poisoned-app
```
*Simulates compromised container registry with embedded reverse shell*

#### 2. Lateral Movement - Service Account Theft
**File:** `attacks/lateral-movement/serviceaccount-theft.yaml`
```bash
kubectl apply -f attacks/lateral-movement/serviceaccount-theft.yaml
kubectl exec -it deployment/token-stealer -- /bin/bash
```
*Extracts mounted service account tokens for privilege escalation*

#### 3. DoS - Resource Starvation
**File:** `attacks/dos/node-starvation.yaml`
```bash
kubectl apply -f attacks/dos/node-starvation.yaml
kubectl get pods --all-namespaces
```
*Requests excessive resources to prevent pod scheduling*

### 🟡 Intermediate Level

#### 4. Supply Chain - Webhook Mutator Bypass
**File:** `attacks/supply-chain/webhook-mutator.yaml`
```bash
kubectl apply -f attacks/supply-chain/webhook-mutator.yaml
kubectl get mutatingwebhookconfigurations
```
*Bypasses admission webhooks with JSON patch fuzzing*

#### 5. Lateral Movement - Kubelet API Abuse
**File:** `attacks/lateral-movement/kubelet-api.yaml`
```bash
kubectl apply -f attacks/lateral-movement/kubelet-api.yaml
kubectl exec -it deployment/kubelet-abuser -- curl -k https://localhost:10250/pods
```
*Accesses kubelet API to extract pod logs and secrets*

#### 6. Persistence - CronJob Backdoor
**File:** `attacks/persistence/cronjob-backdoor.yaml`
```bash
kubectl apply -f attacks/persistence/cronjob-backdoor.yaml
kubectl get cronjobs
```
*Creates scheduled reverse shells for persistent access*

#### 7. DoS - API Server Watch Flood
**File:** `attacks/dos/api-server-watch-spam.yaml`
```bash
kubectl apply -f attacks/dos/api-server-watch-spam.yaml
kubectl get events --sort-by='.lastTimestamp' | tail -10
```
*Exhausts API server connections with persistent watch requests*

### 🟠 Advanced Level

#### 8. Supply Chain - Image Tag Confusion
**File:** `attacks/supply-chain/tag-confusion.yaml`
```bash
kubectl apply -f attacks/supply-chain/tag-confusion.yaml
kubectl get deployments --watch
```
*Exploits mutable image tags for supply chain attacks*

#### 9. Lateral Movement - DaemonSet Escalation
**File:** `attacks/lateral-movement/daemonset-escalation.yaml`
```bash
kubectl apply -f attacks/lateral-movement/daemonset-escalation.yaml
kubectl get daemonsets
```
*Creates privileged DaemonSet for cluster-wide root access*

#### 10. Persistence - Log Tampering
**File:** `attacks/persistence/log-tampering.yaml`
```bash
kubectl apply -f attacks/persistence/log-tampering.yaml
kubectl get events --field-selector reason=SecurityAlert
```
*Deletes Kubernetes events to destroy audit trail*

#### 11. DoS - DNS Amplification
**File:** `attacks/dos/dns-amplification.yaml`
```bash
kubectl apply -f attacks/dos/dns-amplification.yaml
kubectl logs -n kube-system deployment/coredns
```
*Overloads CoreDNS with recursive query floods*

### 🔴 Expert Level

#### 12. Lateral Movement - etcd SSRF
**File:** `attacks/lateral-movement/etcd-ssrf.yaml`
```bash
kubectl apply -f attacks/lateral-movement/etcd-ssrf.yaml
kubectl exec -it deployment/etcd-ssrf -- /bin/bash
```
*Server-Side Request Forgery to access etcd secrets*

#### 13. Persistence - LD_PRELOAD Rootkit
**File:** `attacks/persistence/image-rootkit.yaml`
```bash
kubectl apply -f attacks/persistence/image-rootkit.yaml
kubectl exec -it deployment/rootkit-pod -- ps aux
```
*Hides processes and connections using shared library injection*

#### 14. Persistence - CNI Plugin Hijacking
**File:** `attacks/persistence/cni-interception.yaml`
```bash
kubectl apply -f attacks/persistence/cni-interception.yaml
kubectl get pods -n kube-system | grep cni
```
*Modifies CNI configuration for network traffic interception*

#### 15. DoS - PVC Exhaustion
**File:** `attacks/dos/pvc-full.yaml`
```bash
kubectl apply -f attacks/dos/pvc-full.yaml
kubectl get persistentvolumeclaims
```
*Fills persistent volumes to disrupt application storage*

## 🛡️ Defense Capabilities

### Automated Remediation System

**Immediate Response to Threats:**
```bash
# Deploy automated remediation
kubectl apply -f defenses/remediation/

# Monitor quarantined pods
kubectl get pods --all-namespaces -l security.kubernetes.io/quarantined=true

# Review collected evidence
kubectl get configmaps -n forensics-evidence
```

**Components:**
- **Pod Quarantine**: Automatic isolation of compromised containers
- **Evidence Collection**: Forensic preservation of attack artifacts
- **Alert Escalation**: Notifications to security teams (Slack/Email/PagerDuty)

### Admission Control

**Kyverno Policies:**
```bash
# Require security labels and drop capabilities
kubectl apply -f policies/kyverno/require-security-labels.yaml
kubectl apply -f policies/kyverno/require-drop-capabilities.yaml

# Block latest tags and host path mounts
kubectl apply -f policies/kyverno/disallow-latest-tag.yaml
kubectl apply -f policies/kyverno/disallow-host-path.yaml
```

**OPA Gatekeeper:**
```bash
# Enforce pod security and resource limits
kubectl apply -f policies/opa/pod-security-constraints.yaml
kubectl apply -f policies/opa/resource-limits.yaml
```

### Runtime Security (27 Detection Rules)

**Falco Rules Coverage:**
- **API Abuse** (5 rules): Secret access, token misuse, privilege escalation
- **File Access** (4 rules): Sensitive files, CNI configs, kubectl execution
- **Network Anomalies** (5 rules): etcd access, DNS abuse, SSH connections
- **Privilege Escalation** (3 rules): Privileged containers, dangerous capabilities
- **Persistence** (3 rules): CronJobs, rootkits, log tampering
- **Image Security** (2 rules): Non-standard registries, tag usage
- **RBAC Abuse** (2 rules): Service account mounting, secret access
- **System Resource Abuse** (3 rules): Privileged DaemonSets, host networking

**Monitoring:**
```bash
# Watch Falco alerts
kubectl logs -f -n falco daemonset/falco

# Analyze audit logs
./monitors/audit-logs/analyze-audit.sh /var/log/audit/audit.log
```

### Network Security

**Zero Trust Networking:**
```bash
# Default deny all traffic
kubectl apply -f defenses/networkpolicies/default-deny.yaml

# Allow specific service communication
kubectl apply -f defenses/networkpolicies/allow-frontend-to-backend.yaml

# Emergency traffic blocking
kubectl apply -f defenses/networkpolicies/emergency-block.yaml
```

### Pod Security Standards

**Enforcement Levels:**
```bash
# Restricted (highest security)
kubectl label namespace production pod-security.kubernetes.io/enforce=restricted

# Baseline (balanced security)
kubectl label namespace staging pod-security.kubernetes.io/enforce=baseline

# Privileged (development only)
kubectl label namespace dev pod-security.kubernetes.io/enforce=privileged
```

## 🧪 Testing & Validation

### Automated Test Suite

**Run Comprehensive Validation:**
```bash
# Execute all scenario tests
./tests/test-runner.sh

# Validate defense effectiveness
./tests/validators/validate-defenses.sh

# Generate performance dashboard
./dashboard/generate-dashboard.sh
```

### Test Coverage

- **15 Attack Scenarios**: Automated deployment and validation
- **Defense Validation**: 20+ security control checks
- **Cluster Health**: Node/pod status and security posture
- **Scoring System**: Quantitative measurement of offensive/defensive effectiveness

### Manual Testing

**Red Team Exercises:**
```bash
# Follow detailed attack walkthroughs
cat playbooks/RED_TEAM_PLAYBOOK.md

# Execute specific scenarios
kubectl apply -f attacks/supply-chain/poisoned-image.yaml
```

**Blue Team Exercises:**
```bash
# Follow defensive procedures
cat playbooks/BLUE_TEAM_PLAYBOOK.md

# Monitor and respond to threats
kubectl get pods -l security.kubernetes.io/quarantined=true
```

## 📊 CI/CD Security Pipeline

The GitHub Actions workflow (`.github/workflows/security.yml`) runs comprehensive security validation:

### Pipeline Stages

1. **🔍 Static Analysis**
   - `kubeconform`: Manifest validation
   - `kubescape`: NSA/CISA hardening guide compliance
   - `kube-linter`: Best practices checking

2. **📋 Policy Validation**
   - `Kyverno CLI`: Dry-run policy evaluation
   - `OPA test`: Rego policy testing
   - Custom security rules

3. **🧪 Runtime Testing**
   - Attack scenario validation
   - Defense effectiveness testing
   - Automated remediation verification

4. **📈 Reporting**
   - Security score calculation
   - Compliance dashboard
   - Failure notifications

### Local Pipeline Execution

```bash
# Run security checks locally
./scripts/run-security-pipeline.sh

# Validate against CIS benchmarks
kube-bench run --targets master,node,etcd,policies

# Check Kyverno policy violations
kyverno apply policies/kyverno/ --resource manifests/
```

## � Red & Blue Team Playbooks

### Red Team Playbook (`playbooks/RED_TEAM_PLAYBOOK.md`)

**Offensive Exercises with Difficulty Progression:**
- **Beginner**: Basic attacks, clear indicators (Poisoned images, token theft)
- **Intermediate**: Stealth techniques, evasion (Webhook bypass, kubelet abuse)
- **Advanced**: Complex chains, custom tooling (Tag confusion, DaemonSet escalation)
- **Expert**: Novel techniques, zero detection (etcd SSRF, CNI hijacking)

**Features:**
- Step-by-step attack walkthroughs
- Scoring system with bonus points
- Evasion techniques and countermeasures
- Chaining attack methodologies

### Blue Team Playbook (`playbooks/BLUE_TEAM_PLAYBOOK.md`)

**Defensive Exercises and Procedures:**
- **Prevention**: Admission control, network policies, PSS
- **Detection**: Falco rules, audit logging, anomaly detection
- **Response**: Automated remediation, incident handling, forensics
- **Hardening**: CIS benchmarks, security best practices

**Features:**
- Comprehensive defense implementation
- Threat hunting methodologies
- Incident response procedures
- Security monitoring dashboards

### Exercise Execution

```bash
# Start with beginner scenarios
kubectl apply -f attacks/supply-chain/poisoned-image.yaml
kubectl apply -f attacks/lateral-movement/serviceaccount-theft.yaml

# Monitor blue team response
kubectl logs -f -n falco daemonset/falco
kubectl get events --field-selector reason=SecurityAlert

# Check automated remediation
kubectl get pods -l security.kubernetes.io/quarantined=true
kubectl get configmaps -n forensics-evidence
```

## 🏆 Scoring & Leaderboards

### Performance Dashboard

**Generate Comprehensive Reports:**
```bash
./dashboard/generate-dashboard.sh
```

**Metrics Tracked:**
- **Lab Readiness Score**: Overall system health (0-100)
- **Test Effectiveness**: Attack success vs defense blocking (0-100)
- **Defense Score**: Security control validation (0-100)
- **Cluster Health**: Infrastructure stability (0-100)
- **Security Posture**: Hardening effectiveness (0-100)

### Scoring Examples

```
🟢 Excellent (90-100%): Enterprise-ready with advanced capabilities
🟡 Good (75-89%): Solid foundation with minor gaps
🟠 Needs Work (50-74%): Functional but requires improvements
🔴 Critical (0-49%): Major security issues present
```

### Leaderboard Categories

- **Red Team**: Attack success rate, stealth, speed
- **Blue Team**: Detection rate, response time, coverage
- **Overall**: Combined offensive/defensive effectiveness

## 🎯 Learning Paths

### Beginner Path (1-2 weeks)
1. Set up lab environment
2. Execute 3 beginner scenarios
3. Implement basic defenses
4. Run validation tests
5. Generate first dashboard report

### Intermediate Path (2-4 weeks)
1. Complete all intermediate attacks
2. Deploy comprehensive monitoring
3. Practice incident response
4. Tune detection rules
5. Achieve 80%+ lab readiness score

### Advanced Path (1-2 months)
1. Master expert-level scenarios
2. Implement zero-trust architecture
3. Develop custom attack tools
4. Build automated compliance
5. Participate in CTF competitions

### Expert Path (Ongoing)
1. Research novel attack techniques
2. Contribute to security tooling
3. Develop advanced evasion methods
4. Create custom training scenarios
5. Mentor other security practitioners

## 🔧 Troubleshooting

### Common Issues

**Pods Not Starting:**
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous
```

**Tests Failing:**
```bash
# Check test output
./tests/test-runner.sh --run test-supply-chain-poisoned-image

# Validate cluster state
kubectl get nodes
kubectl get pods --all-namespaces
```

**Defenses Not Working:**
```bash
# Check Kyverno/OPA status
kubectl get clusterpolicies
kubectl get constrainttemplates

# Verify Falco rules
kubectl get configmaps -n falco
```

**Remediation Not Triggering:**
```bash
# Check remediation components
kubectl get pods -n security-remediation

# Verify webhook configuration
kubectl get mutatingwebhookconfigurations
```

### Getting Help

1. **Documentation**: Check `docs/` directory and playbooks
2. **Logs**: Review component logs with `kubectl logs`
3. **Dashboard**: Run `./dashboard/generate-dashboard.sh` for diagnostics
4. **Issues**: File GitHub issues with detailed reproduction steps

## 🛠️ Security Tools

## 🧪 Running the Lab

### Full Attack Suite

```bash
# Run all attack scenarios
bash scripts/run_attack_suite.sh

# View results
kubectl get events --sort-by='.lastTimestamp'
kubectl logs -n falco -l app=falco
```

### Manual Testing

```bash
# Test admission policies
kubectl apply -f attacks/rbac-misuse/malicious-pod.yaml
# Should be denied by Kyverno/OPA

# Test network policies
kubectl run test-pod --image=busybox -- sleep 3600
kubectl exec test-pod -- wget -O- http://external-evil-site.com
# Should fail due to NetworkPolicy
```

## 📈 Metrics & Monitoring

- **Policy Violations**: Track Kyverno/OPA denials
- **Runtime Alerts**: Falco security events
- **Attack Success Rate**: Test defense effectiveness
- **Response Time**: Time to detect and block attacks

## 🤝 Contributing

1. Fork the repository
2. Create attack/defense scenarios
3. Add detection rules (Falco/OPA/Kyverno)
4. Submit pull request with documentation

## 📚 Resources

- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [NSA/CISA Kubernetes Hardening Guide](https://media.defense.gov/2022/Aug/29/2003066362/-1/-1/0/CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF)
- [Kyverno Documentation](https://kyverno.io/docs/)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)
- [Falco Rules](https://falco.org/docs/rules/)

## 📝 License

MIT License - see [LICENSE](LICENSE) file

## 👤 Author

**Pawan Bharambe**
- DevOps Engineer specializing in Kubernetes & Cloud Security
- GitHub: [@pawan122003](https://github.com/pawan122003)
- Focus: Container Security, Policy-as-Code, DevSecOps

## ⭐ Show Your Support

Give a ⭐ if this lab helped you learn Kubernetes security!

---

**⚠️ Warning**: This is a lab environment for educational purposes. Do not deploy these attack scenarios in production environments.
