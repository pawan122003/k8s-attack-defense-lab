# Kubernetes Attack & Defense Lab - Enhanced Edition

![K8s Security](https://img.shields.io/badge/Kubernetes-Security-326CE5?logo=kubernetes)
![Attacks](https://img.shields.io/badge/Scenarios-15+-red?logo=security)
![Detection](https://img.shields.io/badge/Falco%20Rules-20+-blue)
![License](https://img.shields.io/badge/License-MIT-green.svg)

> **Enterprise-grade Kubernetes security lab with 15+ advanced attack scenarios, comprehensive detection rules, and automated response workflows**

## 🎯 What's New: Advanced Capabilities

This enhanced version adds:

- **15+ Advanced Attack Scenarios** (3 original + 12 new)
- **Supply Chain Attacks** (poisoned images, webhook bypass, tag confusion)
- **Lateral Movement** (token theft, Kubelet API, DaemonSet escalation, etcd access)
- **Persistence Mechanisms** (rootkits, log tampering, CronJobs, CNI hijacking)
- **Denial of Service** (API flooding, resource starvation, DNS amplification, disk exhaustion)
- **36 Falco Detection Rules** (API abuse, file access, network anomalies, privilege escalation)
- **Automated Forensics** (evidence collection, timeline reconstruction, audit log analysis)
- **Test Automation** (validation suite, playbooks, scoring dashboard)

## 📊 Scenarios at a Glance

### Phase 1: Original Attacks (3 scenarios)
| Attack | Vector | Impact |
|--------|--------|--------|
| **RBAC Misuse** | Overprivileged ServiceAccount | Cluster-admin access |
| **Secrets Exfil** | Volume mount access | Credential theft |
| **HostPath Escape** | Privileged pod + hostPath | Node compromise |

### Phase 2: Supply Chain (3 new scenarios)  
| Attack | Vector | Impact |
|--------|--------|--------|
| **Poisoned Image** | Compromised registry | Cluster-wide backdoor |
| **Webhook Bypass** | Admission control fuzzing | Privileged pod injection |
| **Tag Confusion** | Mutable image tags | Rolling compromise |

**Location**: [`attacks/supply-chain/`](attacks/supply-chain/)
**Detection**: Image source validation, tag immutability policies, Kyverno admission rules
**Defense**: Binary authorization, image scanning, signature verification

### Phase 3: Lateral Movement (4 new scenarios)
| Attack | Vector | Impact |
|--------|--------|--------|
| **Token Theft** | /var/run/secrets mounting | Privilege escalation |
| **Kubelet API** | Unauthenticated localhost:10250 | Log/secret access |
| **DaemonSet** | Privileged pod on every node | Full cluster compromise |
| **etcd Access** | SSRF to etcd endpoint | All secrets exposed |

**Location**: [`attacks/lateral-movement/`](attacks/lateral-movement/)
**Detection**: Token usage anomalies, Kubelet port access, DaemonSet privilege patterns
**Defense**: Network policies, Kubelet authentication, RBAC restrictions

### Phase 4: Persistence (4 new scenarios)
| Attack | Vector | Impact |
|--------|--------|--------|
| **Image Rootkit** | LD_PRELOAD backdoor | Command interception |
| **Log Tampering** | API event deletion | Evidence destruction |
| **CronJob Backdoor** | Hidden scheduled shell | Periodic access |
| **CNI Hijacking** | Plugin modification | Network eavesdropping |

**Location**: [`attacks/persistence/`](attacks/persistence/)
**Detection**: Unusual process spawning, log gaps, CronJob anomalies, CNI modifications
**Defense**: Pod security policies, immutable logs, file integrity monitoring

### Phase 5: Denial of Service (4 new scenarios)
| Attack | Vector | Impact |
|--------|--------|--------|
| **API Flooding** | Watch request spam | API server exhaustion |
| **Resource Starvation** | Large resource requests | Scheduling failure |
| **DNS Amplification** | CoreDNS query flood | Service discovery failure |
| **PVC Exhaustion** | Disk fill attack | Application crash |

**Location**: [`attacks/dos/`](attacks/dos/)
**Detection**: Connection pool spike, scheduling failures, DNS latency spikes, disk pressure
**Defense**: Resource quotas, PVC limits, rate limiting, DNS policy

## 🛡️ Detection & Response

### Falco Runtime Rules (20+)
Located in [`monitors/falco/advanced-rules.yaml`](monitors/falco/advanced-rules.yaml)

**Coverage**:
- 5 API server abuse rules (secret access, token misuse, privilege escalation)
- 4  file access rules (sensitive files, tokens, CNI configs, kubectl execution)
- 5 network anomaly rules (etcd, Kubelet, external connections, DNS, SSH)
- 3 privilege escalation rules (privileged containers, capabilities, hostPath)
- 3 persistence indicators (CronJobs, rootkits, log tampering)
- 2 DoS indicators (API connection spikes, resource exhaustion)

**Deployment**:
```bash
kubectl apply -f monitors/falco/advanced-rules.yaml
```

### Kubernetes Audit Logging
Located in [`monitors/audit-logs/`](monitors/audit-logs/)

**Captures**:
- All secret access (GET, LIST, UPDATE, DELETE)
- RBAC modifications (roles, bindings, ClusterRoles)
- Pod creation/deletion and exec operations
- Event deletions (log tampering indicator)
- Webhook modifications (admission bypass attempts)

**Configuration**:
```yaml
# In kube-apiserver manifest:
--audit-policy-file=/etc/kubernetes/audit-policy.yaml
--audit-log-maxage=30 --audit-log-maxbackup=10 --audit-log-maxsize=100
```

### Forensics & Evidence Collection
Located in [`monitors/forensics/`](monitors/forensics/)

**Automated Collection**:
```bash
./collect-evidence.sh [namespace] [pod-name]
```

**Collects**:
- Pod specifications and descriptions
- Container logs and previous logs
- Environment variables and processes
- Network connections and mounted volumes
- Events and RBAC configuration
- Cluster state and audit logs

**Analysis**:
```bash
./analyze-audit.sh /var/log/audit/audit.log
```

Generates attack timeline, identifies log gaps, calculates risk score

## 🚀 Quick Start

### 1. Deploy Lab Cluster
```bash
# Create Kind cluster with Falco monitoring
kind create cluster --config cluster/kind-config.yaml

# Install monitoring tools
./scripts/install_tools.sh
```

### 2. Deploy All Attacks
```bash
# Supply chain attacks
kubectl apply -f attacks/supply-chain/

# Lateral movement scenarios
kubectl apply -f attacks/lateral-movement/

# Persistence mechanisms
kubectl apply -f attacks/persistence/

# Denial of Service
kubectl apply -f attacks/dos/

# Original attacks
kubectl apply -f attacks/rbac-misuse/
kubectl apply -f attacks/secrets-exfil/
kubectl apply -f attacks/hostpath-escape/
```

### 3. Monitor with Falco
```bash
# Deploy Falco with advanced rules
kubectl apply -f monitors/falco/advanced-rules.yaml

# Watch for alerts
kubectl logs -f -n falco daemonset/falco
```

### 4. Collect Forensics
```bash
# Evidence collection
./monitors/forensics/collect-evidence.sh supply-chain-attack poisoned-app

# Audit analysis
./monitors/audit-logs/analyze-audit.sh /var/log/audit/audit.log
```

## 📚 Documentation

| Document | Contents |
|----------|----------|
| [`docs/attacks.md`](docs/attacks.md) | Detailed attack walkthroughs and exploitation techniques |
| [`docs/defenses.md`](docs/defenses.md) | Defense strategies, policy configurations, best practices |
| [`playbooks/RED_TEAM_PLAYBOOK.md`](playbooks/RED_TEAM_PLAYBOOK.md) | Step-by-step attack execution guides |
| [`playbooks/BLUE_TEAM_PLAYBOOK.md`](playbooks/BLUE_TEAM_PLAYBOOK.md) | Detection and response procedures |
| [`playbooks/CTF_CHALLENGES.md`](playbooks/CTF_CHALLENGES.md) | Competitive security challenges |

## 🧪 Validation & Testing

### Automated Test Suite
```bash
tests/test-runner.sh                    # Run all tests
tests/test-runner.sh --attack [name]    # Test specific attack
tests/test-runner.sh --defense [name]   # Verify defense blocks attack
```

**Test Coverage**:
- Attack deployment and objective verification
- Defense policy enforcement
- Detection rule triggering
- Remediation and isolation
- Forensics collection

### Scoring Dashboard
```bash
# Generate metrics and scorecards
./dashboard/generate-report.py

# View real-time metrics
open dashboard/dashboard.html
```

**Metrics Tracked**:
- Red team: attacks succeeded, detected, time-to-compromise
- Blue team: detection rate, response time, false positives
- Coverage: % of attacks detected, % blocked, unprotected vectors

## 📁 Project Structure

```
k8s-attack-defense-lab/
│
├── attacks/ (15+ scenarios)
│   ├── supply-chain/
│   │   ├── poisoned-image.yaml
│   │   ├── webhook-mutator.yaml
│   │   └── tag-confusion.yaml
│   ├── lateral-movement/
│   │   ├── serviceaccount-theft.yaml
│   │   ├── kubelet-api.yaml
│   │   ├── daemonset-escalation.yaml
│   │   └── etcd-ssrf.yaml
│   ├── persistence/
│   │   ├── image-rootkit.yaml
│   │   ├── log-tampering.yaml
│   │   ├── cronjob-backdoor.yaml
│   │   └── cni-interception.yaml
│   ├── dos/
│   │   ├── api-server-watch-spam.yaml
│   │   ├── node-starvation.yaml
│   │   ├── dns-amplification.yaml
│   │   └── pvc-full.yaml
│   ├── rbac-misuse/
│   ├── secrets-exfil/
│   └── hostpath-escape/
│
├── defenses/
│   ├── networkpolicies/
│   ├── podsecurity/
│   ├── rbac/
│   ├── remediation/         # Automated isolation
│   └── alerting/            # Response workflows
│
├── monitors/
│   ├── falco/
│   │   ├── advanced-rules.yaml      # 20+ detection rules
│   │   └── values.yaml
│   ├── audit-logs/
│   │   ├── audit-policy.yaml        # API audit configuration
│   │   └── analyze-audit.sh         # Log analysis tool
│   ├── metrics/                     # Baseline collection
│   └── forensics/
│       └── collect-evidence.sh      # Automated evidence gathering
│
├── tests/                   # Validation suite
│   ├── scenarios/          # Attack tests
│   ├── validators/         # Verification logic
│   └── results/            # Test history
│
├── playbooks/              # Documentation
│   ├── RED_TEAM_PLAYBOOK.md
│   ├── BLUE_TEAM_PLAYBOOK.md
│   └── CTF_CHALLENGES.md
│
├── dashboard/              # Metrics & scoring
│   ├── generate-report.py
│   └── dashboard.html
│
├── ctf/                    # CTF infrastructure
│   ├── scoreboard.py
│   └── challenges.yaml
│
├── scripts/
│   ├── setup-complete-lab.sh
│   ├── run-red-team-exercises.sh
│   ├── run-blue-team-exercises.sh
│   └── reset-cluster.sh
│
├── cluster/
│   └── kind-config.yaml    # 2-node K8s cluster
│
├── policies/
│   ├── kyverno/            # Admission policies
│   └── opa/                # Authorization policies
│
└── docs/
    ├── attacks.md
    ├── defenses.md
    ├── ARCHITECTURE.md
    ├── SETUP_GUIDE.md
    └── CTF_INSTRUCTIONS.md
```

## 🎓 Learning Path

### Beginner: Understand Attacks
1. Read [`attacks/supply-chain/README.md`](attacks/supply-chain/README.md)
2. Deploy supply chain scenarios: `kubectl apply -f attacks/supply-chain/`
3. Observe in Falco: `kubectl logs -f -n falco daemonset/falco`
4. Follow [`playbooks/RED_TEAM_PLAYBOOK.md`](playbooks/RED_TEAM_PLAYBOOK.md)

### Intermediate: Implement Defenses
1. Read [`defenses/`](defenses/) policy configurations
2. Deploy policies: `kubectl apply -f defenses/`
3. Re-run attacks → verify they're blocked
4. Tune false positives in Falco rules

### Advanced: Full Response
1. Deploy all scenarios
2. Set up forensics collection: `./monitors/forensics/collect-evidence.sh`
3. Analyze audit logs: `./monitors/audit-logs/analyze-audit.sh`
4. Run test suite: `tests/test-runner.sh`
5. Generate scorecard: `dashboard/generate-report.py`

### Expert: CTF Competition
1. Review [`playbooks/CTF_CHALLENGES.md`](playbooks/CTF_CHALLENGES.md)
2. Complete challenges without guidance
3. Reconstruct attack timelines
4. Achieve 100% detection coverage

## 📊 Scenarios Progression

```
┌─────────────────────────────────────────────────────────────┐
│          Scenario Difficulty & Complexity                    │
├─────────────────────────────────────────────────────────────┤
│ ★           HostPath Escape                                 │
│             RBAC Misuse                                     │
│             Secrets Exfil                                   │
│                                                              │
│ ★★          Poisoned Image                                  │
│             API Watch Flooding                              │
│             Token Theft                                     │
│                                                              │
│ ★★★         Webhook Bypass                                  │
│             DaemonSet Escalation                            │
│             Log Tampering                                   │
│             etcd SSRF                                       │
│                                                              │
│ ★★★★        Tag Confusion                                   │
│             Image Rootkit                                   │
│             CronJob Backdoor                                │
│             CNI Hijacking                                   │
│             Kubelet API Exploitation                        │
│                                                              │
│ ★★★★★       Multi-stage attacks                             │
│             Supply chain + lateral + persistence           │
│             Combination attacks                             │
└─────────────────────────────────────────────────────────────┘
```

## 🔍 Key Differences: Original vs Enhanced

| Feature | Original | Enhanced |
|---------|----------|----------|
| **Scenarios** | 3 basic attacks | 15+ advanced scenarios |
| **Attack Types** | RBAC, secrets, hostpath | + supply chain, lateral, persistence, DoS |
| **Detection** | 1 Falco rule | 20+ comprehensive rules |
| **Monitoring** | None | Falco + audit logs + metrics |
| **Forensics** | Manual | Automated collection & analysis |
| **Validation** | Manual testing | Automated test suite |
| **Documentation** | Basic | Comprehensive playbooks + CTF |
| **Response** | Manual | Automated remediation |

## 🛠️ Tools Required

```yaml
Required:
  - Docker 20.10+
  - kubectl 1.24+
  - Kind 0.14+

Optional (included in setup):
  - Falco 0.33+ (runtime monitoring)
  - Kyverno 1.9+ (admission control)
  - OPA/Gatekeeper (authorization)
  - Kubescape (RBAC audit)
  - etcd-browser (etcd exploration)
```

## 📝 Contributing

To add new scenarios:

1. Create new directory: `attacks/[category]/[name].yaml`
2. Include: Deployment, documentation, detection rules
3. Update: Falco rules, playbooks, test suite
4. Document: README for scenario with attack/defense guide
5. Add test: `tests/scenarios/test-[name].sh`

## ⚠️ Important Notes

- **This is a lab environment**: Not for production use
- **Kind cluster is ephemeral**: Data not persisted
- **Attack scenarios are simulated**: Real exploits are more complex
- **Network isolation required**: Run in isolated network
- **Learning purpose only**: For authorized security testing

## 📖 References

- [MITRE K8s Attack Matrix](https://attack.mitre.org/)
- [OWASP Kubernetes Security](https://owasp.org/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Falco Rules Documentation](https://falco.org/docs/)
- [Kyverno Policies](https://kyverno.io/)
- [OPA/Gatekeeper Policies](https://open-policy-agent.org/)

## 📄 License

MIT License - See [LICENSE](LICENSE) for details

## 🤝 Support

For questions or issues:
1. Check [`docs/`](docs/) for detailed guides
2. Review [`playbooks/`](playbooks/) for procedures
3. Examine [`monitors/forensics/EVIDENCE_MANIFEST.txt`](monitors/forensics/) for analysis tips

---

**Happy securing!** 🔒

*Last Updated: 2024*
*Scenarios: 15+ | Detection Rules: 20+ | Enterprise-grade lab for Kubernetes security*
