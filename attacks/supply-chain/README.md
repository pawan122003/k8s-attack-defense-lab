# Supply Chain Attack Scenarios

## Overview
This directory contains advanced supply chain attack scenarios for the K8s attack-defense lab. These attacks focus on compromising the container image supply chain and admission control mechanisms.

## Scenarios

### 1. Poisoned Container Registry Attack
**File**: `poisoned-image.yaml`

**Description**: 
Simulates an attacker compromising a private container registry and pushing malicious images that appear legitimate.

**Attack Flow**:
1. Attacker gains access to organization's container registry credentials
2. Attacker pushes malicious image with embedded backdoor
3. Image uses legitimate application name (e.g., `app:v1.2.3`)
4. Developers unknowingly deploy the poisoned image
5. Reverse shell backdoor established on pod startup
6. Attacker gains cluster access

**Key Indicators**:
- Image pulled from unexpected registry mirror
- Container performs network connections to attacker C2
- Suspicious processes spawned during container init
- Unexpected outbound traffic patterns

**Impact**:
- Cluster-wide compromise through legitimate deployment process
- Persistence through application lifecycle
- Difficult to detect if integration scanning is bypassed

**Defense Mechanisms**:
- Image signature verification (Notary)
- Binary authorization policies
- Registry scanning for vulnerabilities/malware
- Network policies restricting outbound traffic
- File integrity monitoring

---

### 2. Admission Webhook Bypass Attack
**File**: `webhook-mutator.yaml`

**Description**: 
Demonstrates how an attacker can exploit vulnerabilities in admission webhook implementations to inject malicious containers.

**Attack Flow**:
1. Attacker identifies vulnerability in validating webhook logic
2. Crafts admission request with JSON patch that confuses webhook parser
3. Webhook fails to properly validate the injected container
4. Mutating webhook accepts modified pod specification
5. Privileged init container injected alongside legitimate application
6. Init container escapes container boundary and compromises host

**Exploitation Techniques**:
- JSON deserialization errors causing validation bypass
- Field reordering causing parser confusion
- Resource version conflicts in webhook responses
- Race conditions between multiple webhooks
- Webhook scope restriction bypass (modifying other namespaces)

**Key Indicators**:
- Unexpected init/sidecar containers in pod specs
- Privileged containers appearing in restricted namespaces
- Unusual capabilities granted to containers
- Admission webhook audit log irregularities

**Impact**:
- Privilege escalation through container injection
- Bypass of security policies
- Host compromise through privileged pod escape

**Defense Mechanisms**:
- Pod Security Standards enforcing container restrictions
- Kyverno policies validating container specifications
- OPA/Rego policies preventing privilege escalation
- Webhook scope restrictions and field validation
- Audit logging of all webhooks config changes

---

### 3. Image Tag Confusion Attack
**File**: `tag-confusion.yaml`

**Description**:
Exploits the mutability of container image tags in registries. An attacker re-pushes a different (malicious) image to a previously-used tag.

**Attack Flow**:
1. Organization builds and pushes legitimate `app:v1.0` 
   - Digest: `sha256:abc123...` (clean image)
2. Image deployed across cluster using tag reference
3. Attacker compromises registry access
4. Attacker builds malicious version and pushes to `app:v1.0`
   - Digest: `sha256:xyz789...` (malware)
5. Pod restart or cache invalidation triggers new image pull
6. Same tag `v1.0` now resolves to malicious digest
7. New pods launched receive compromised image

**Why This Works**:
- Container tags are mutable in most registries
- Image digests (SHA256) are immutable
- Platforms often cache images by tag, not digest
- `imagePullPolicy: Always` or pod restart cycles invalidate cache

**Key Indicators**:
- Image digest mismatch for same tag
- Unexpected image pulls after deployment stabilization
- Image content hash verification failures
- Multiple digests for same tag in audit logs

**Impact**:
- Compromises new pod replicas launched after attack
- Can be used for rolling compromise without alerting users
- Difficult to detect if old cached pods continue running

**Defense Mechanisms**:
- Use image digest instead of tag for deployment
- Image tag immutability policies in registry
- Container Image Signing (cosign, Notary)
- Software Bill of Materials (SBoM) verification
- Pre-pull and verify images before pod creation
- Image pull verification policies (ImagePolicy admission controller)

---

## Deployment

### Deploy All Supply Chain Attacks
```bash
kubectl apply -f poisoned-image.yaml
kubectl apply -f webhook-mutator.yaml
kubectl apply -f tag-confusion.yaml
```

### Verify Deployment
```bash
# Check all namespaces created
kubectl get ns | grep attack

# View pods in each attack namespace
kubectl get pods -n supply-chain-attack
kubectl get pods -n webhook-attack
kubectl get pods -n tag-confusion-attack
```

### Check Attack Indicators
```bash
# View container logs for backdoor execution
kubectl logs -n supply-chain-attack deployment/poisoned-app app

# Check for injected containers
kubectl get pods -n webhook-attack webhook-fuzzer-app -o jsonpath='{.spec.containers[*].name}'

# Verify tag vs digest usage
kubectl get pods -n tag-confusion-attack -o jsonpath='{.items[*].spec.containers[*].image}'
```

### Cleanup
```bash
kubectl delete ns supply-chain-attack webhook-attack tag-confusion-attack
```

---

## Detection with Falco

The following Falco rules detect these supply chain attacks:

### Rule 1: Image Pull from Non-Standard Registry
```yaml
- rule: Image Pull From Unknown Registry
  desc: Detect image pulls from non-standard registries
  condition: >
    container and
    container_image_repository not in
    (docker.io, gcr.io, registry.official, internal-registry.company.com) and
    spawned_process and
    proc.name = "docker" or "containerd"
  output: >
    Unusual image pull detected
    (image=%container_image repository=%container_image_repository)
```

### Rule 2: Unexpected Container Injection
```yaml
- rule: Unexpected Init Container Injection
  desc: Detect suspicious init container injection
  condition: >
    k8s_audit and
    ka.verb = "create" and
    ka.target.resource = "pods" and
    contains(request_object, "initContainers") and
    request_object.spec.initContainers >
    baseline_init_container_count
  output: >
    Unexpected init container added to pod
    (pod=%ka.target.name namespace=%ka.target.namespace)
```

### Rule 3: Tag Mismatch Detection
```yaml
- rule: Image Digest Tag Mismatch
  desc: Detect image tag to digest mismatches
  condition: >
    container and
    image_tag_changed_since_launch and
    container_image_digest !=
    baseline_digest_for_tag
  output: >
    Image tag resolved to unexpected digest
    (tag=%container_image_tag
     expected_digest=%baseline_digest_for_tag
     actual_digest=%container_image_digest)
```

---

## Kyverno Policies for Defense

Policy to prevent image tag usage:
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-image-digest
spec:
  validationFailureAction: audit # or enforce
  rules:
  - name: check-image-digest
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Images must use digest reference, not tags"
      pattern:
        spec:
          containers:
          - image: "*//*@sha256:*"
```

---

## OPA Policy for Admission Webhook Validation

```rego
package kubernetes.admission

deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    
    # Check for privileged containers in restricted namespace
    container.securityContext.privileged == true
    input.request.namespace in ["default", "development"]
    
    msg := sprintf(
        "Privileged containers not allowed in namespace %v",
        [input.request.namespace]
    )
}

deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.initContainers[_]
    
    # Unexpected init containers in production namespaces
    input.request.namespace == "production"
    container.name not in data.approved_init_containers[_]
    
    msg := sprintf(
        "Init container %v not in approved list for production",
        [container.name]
    )
}
```

---

## Impact Assessment

| Attack | Severity | Detection Difficulty | Prevention Difficulty |
|--------|----------|----------------------|----------------------|
| Poisoned Registry | **CRITICAL** | Medium | Medium (requires scanning + verification) |
| Webhook Bypass | **CRITICAL** | High | High (requires robust webhook design) |
| Tag Confusion | **HIGH** | Medium | Low (use digests instead of tags) |

---

## References

- **Supply Chain**: https://attack.mitre.org/matrices/enterprise/cloud/
- **Image Security**: Cloud Native Security Whitepaper
- **Admission Controllers**: K8s documentation on admission webhooks
- **Supply Chain Defense**: SLSA Framework (Security and Supply Chain Levels for Artifacts)
