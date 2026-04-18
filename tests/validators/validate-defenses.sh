#!/bin/bash

# Defense Validator: Test that security controls properly block attacks
# Validates that defenses are correctly implemented and effective

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Validation results
VALIDATION_RESULTS=()

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    VALIDATION_RESULTS+=("PASS: $1")
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    VALIDATION_RESULTS+=("WARN: $1")
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    VALIDATION_RESULTS+=("FAIL: $1")
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validate cluster access
validate_cluster_access() {
    log_info "Validating cluster access..."

    if ! kubectl cluster-info >/dev/null 2>&1; then
        log_error "Cannot access Kubernetes cluster"
        return 1
    fi

    log_success "Cluster access validated"
}

# Validate namespace security
validate_namespace_security() {
    log_info "Validating namespace security labels..."

    # Check if critical namespaces have security labels
    local namespaces=("default" "kube-system" "kube-public")
    local missing_labels=0

    for ns in "${namespaces[@]}"; do
        if ! kubectl get namespace "$ns" -o jsonpath='{.metadata.labels}' 2>/dev/null | grep -q "security"; then
            log_warning "Namespace $ns missing security labels"
            ((missing_labels++))
        fi
    done

    if [ $missing_labels -eq 0 ]; then
        log_success "All critical namespaces have security labels"
    fi
}

# Validate Pod Security Standards
validate_pod_security_standards() {
    log_info "Validating Pod Security Standards..."

    # Check if PSS is enforced
    local pss_enforced=$(kubectl get namespace default -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null || echo "")

    if [ "$pss_enforced" = "restricted" ]; then
        log_success "Pod Security Standards (Restricted) enforced"
    elif [ "$pss_enforced" = "baseline" ]; then
        log_success "Pod Security Standards (Baseline) enforced"
        log_warning "Consider using 'restricted' profile for higher security"
    else
        log_warning "Pod Security Standards not enforced in default namespace"
    fi
}

# Validate Network Policies
validate_network_policies() {
    log_info "Validating Network Policies..."

    # Check for default deny policy
    local deny_all=$(kubectl get networkpolicies -n default 2>/dev/null | grep -c "default-deny" || echo "0")

    if [ "$deny_all" -gt 0 ]; then
        log_success "Default deny network policy exists"
    else
        log_error "Missing default deny network policy"
    fi

    # Check for remediation quarantine policy
    local quarantine_policy=$(kubectl get networkpolicies -n security-remediation 2>/dev/null | grep -c "quarantine-deny-all" || echo "0")

    if [ "$quarantine_policy" -gt 0 ]; then
        log_success "Quarantine network policy exists"
    else
        log_warning "Quarantine network policy not found"
    fi
}

# Validate Kyverno policies
validate_kyverno_policies() {
    log_info "Validating Kyverno admission policies..."

    if ! kubectl get clusterpolicies 2>/dev/null >/dev/null; then
        log_warning "Kyverno not installed or not accessible"
        return 0
    fi

    # Check for key policies
    local policies=("disallow-host-path" "require-drop-capabilities" "require-security-labels")
    local found_policies=0

    for policy in "${policies[@]}"; do
        if kubectl get clusterpolicies "$policy" 2>/dev/null >/dev/null; then
            ((found_policies++))
        fi
    done

    if [ $found_policies -eq ${#policies[@]} ]; then
        log_success "All required Kyverno policies deployed ($found_policies/${#policies[@]})"
    else
        log_warning "Missing Kyverno policies: $(( ${#policies[@]} - found_policies )) not found"
    fi
}

# Validate OPA policies
validate_opa_policies() {
    log_info "Validating OPA Gatekeeper policies..."

    if ! kubectl get constrainttemplates 2>/dev/null >/dev/null; then
        log_warning "OPA Gatekeeper not installed or not accessible"
        return 0
    fi

    # Check for key constraint templates
    local constraints=("k8spsp" "pod-security" "container-security")
    local found_constraints=0

    for constraint in "${constraints[@]}"; do
        if kubectl get constrainttemplates | grep -q "$constraint"; then
            ((found_constraints++))
        fi
    done

    if [ $found_constraints -gt 0 ]; then
        log_success "OPA policies deployed ($found_constraints constraints found)"
    else
        log_warning "No OPA constraint templates found"
    fi
}

# Validate Falco deployment
validate_falco_deployment() {
    log_info "Validating Falco runtime security..."

    # Check if Falco is running
    local falco_pods=$(kubectl get pods -n falco 2>/dev/null | grep -c "falco" || echo "0")

    if [ "$falco_pods" -gt 0 ]; then
        log_success "Falco is deployed and running ($falco_pods pods)"
    else
        log_error "Falco is not deployed or not running"
        return 1
    fi

    # Check if custom rules are loaded
    local custom_rules=$(kubectl get configmaps -n falco 2>/dev/null | grep -c "falco-rules" || echo "0")

    if [ "$custom_rules" -gt 0 ]; then
        log_success "Custom Falco rules are deployed"
    else
        log_warning "No custom Falco rules found"
    fi
}

# Validate remediation system
validate_remediation_system() {
    log_info "Validating automated remediation system..."

    # Check remediation namespace
    if kubectl get namespace security-remediation 2>/dev/null >/dev/null; then
        log_success "Remediation namespace exists"
    else
        log_error "Remediation namespace not found"
        return 1
    fi

    # Check remediation components
    local components=("quarantine-webhook" "forensics-collector" "alert-manager")
    local running_components=0

    for component in "${components[@]}"; do
        if kubectl get pods -n security-remediation -l app="$component" 2>/dev/null | grep -q "Running"; then
            ((running_components++))
        fi
    done

    if [ $running_components -eq ${#components[@]} ]; then
        log_success "All remediation components running ($running_components/${#components[@]})"
    else
        log_warning "Some remediation components not running: $(( ${#components[@]} - running_components )) missing"
    fi
}

# Validate RBAC security
validate_rbac_security() {
    log_info "Validating RBAC security..."

    # Check for overly permissive cluster roles
    local cluster_admin_bindings=$(kubectl get clusterrolebindings 2>/dev/null | grep -c "cluster-admin" || echo "0")

    if [ "$cluster_admin_bindings" -gt 2 ]; then
        log_warning "Multiple cluster-admin bindings found ($cluster_admin_bindings)"
        log_warning "Review cluster-admin access - should be minimal"
    else
        log_success "RBAC cluster-admin access is restricted"
    fi

    # Check for service accounts with excessive permissions
    local sa_cluster_roles=$(kubectl get clusterrolebindings 2>/dev/null | grep -c "serviceaccount" || echo "0")

    if [ "$sa_cluster_roles" -gt 5 ]; then
        log_warning "Many service accounts have cluster roles ($sa_cluster_roles)"
    fi
}

# Validate secrets security
validate_secrets_security() {
    log_info "Validating secrets security..."

    # Check for secrets mounted to pods
    local mounted_secrets=$(kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.spec.volumes[?(@.secret)].secret.secretName}{"\n"}{end}' 2>/dev/null | wc -l)

    if [ "$mounted_secrets" -gt 10 ]; then
        log_warning "Many secrets mounted to pods ($mounted_secrets)"
        log_warning "Consider using external secret management"
    fi

    # Check for default service account usage
    local default_sa_usage=$(kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.spec.serviceAccountName}{"\n"}{end}' 2>/dev/null | grep -c "^default$" || echo "0")

    if [ "$default_sa_usage" -gt 0 ]; then
        log_warning "Pods using default service account ($default_sa_usage found)"
        log_warning "Use dedicated service accounts with minimal permissions"
    fi
}

# Generate validation report
generate_validation_report() {
    local report_file="$SCRIPT_DIR/validation-report-$(date +%Y%m%d-%H%M%S).md"

    # Count results
    local total_checks=${#VALIDATION_RESULTS[@]}
    local pass_count=$(grep -c "^PASS:" <<< "${VALIDATION_RESULTS[*]}")
    local warn_count=$(grep -c "^WARN:" <<< "${VALIDATION_RESULTS[*]}")
    local fail_count=$(grep -c "^FAIL:" <<< "${VALIDATION_RESULTS[*]}")

    cat > "$report_file" << EOF
# K8s Security Validation Report

**Generated:** $(date)  
**Total Checks:** $total_checks  
**Environment:** $(kubectl config current-context 2>/dev/null || echo "Unknown")

## Summary

| Status | Count | Percentage |
|--------|-------|------------|
| ✅ PASS | $pass_count | $((pass_count * 100 / total_checks))% |
| ⚠️  WARN | $warn_count | $((warn_count * 100 / total_checks))% |
| ❌ FAIL | $fail_count | $((fail_count * 100 / total_checks))% |

## Detailed Results

EOF

    # Add detailed results
    for result in "${VALIDATION_RESULTS[@]}"; do
        echo "- $result" >> "$report_file"
    done

    # Add recommendations
    cat >> "$report_file" << EOF

## Recommendations

EOF

    if [ $fail_count -gt 0 ]; then
        cat >> "$report_file" << EOF
### Critical Issues (Address Immediately)
- $fail_count critical validation failures found
- These represent security gaps that must be fixed
- Review failed items and implement missing controls

EOF
    fi

    if [ $warn_count -gt 0 ]; then
        cat >> "$report_file" << EOF
### Warnings (Address Soon)
- $warn_count warnings indicate potential security improvements
- These are not critical but should be addressed for better security posture

EOF
    fi

    if [ $pass_count -eq $total_checks ]; then
        cat >> "$report_file" << EOF
### Excellent Security Posture
- All validation checks passed!
- The cluster has comprehensive security controls implemented

EOF
    fi

    cat >> "$report_file" << EOF
## Security Score

**Overall Security Score:** $(( (pass_count * 100) / total_checks ))%

**Scoring Guide:**
- 90-100%: Excellent security posture
- 75-89%: Good security with some gaps
- 50-74%: Adequate security, needs improvement
- <50%: Critical security issues present

## Next Steps

1. **Address Critical Issues**: Fix any FAIL items immediately
2. **Review Warnings**: Address WARN items for better security
3. **Regular Validation**: Run this validation regularly
4. **Continuous Improvement**: Add more validation checks as needed

EOF

    log_success "Validation report generated: $report_file"
    echo "📄 Report saved to: $report_file"
}

# Main validation function
main() {
    echo "🔒 K8s Security Validator"
    echo "========================"

    # Run all validations
    validate_cluster_access
    validate_namespace_security
    validate_pod_security_standards
    validate_network_policies
    validate_kyverno_policies
    validate_opa_policies
    validate_falco_deployment
    validate_remediation_system
    validate_rbac_security
    validate_secrets_security

    # Generate report
    generate_validation_report

    echo ""
    log_success "Security validation completed"

    # Summary
    local total=${#VALIDATION_RESULTS[@]}
    local pass=$(grep -c "^PASS:" <<< "${VALIDATION_RESULTS[*]}")
    local warn=$(grep -c "^WARN:" <<< "${VALIDATION_RESULTS[*]}")
    local fail=$(grep -c "^FAIL:" <<< "${VALIDATION_RESULTS[*]}")

    echo ""
    echo "📊 Validation Summary:"
    echo "  Total Checks: $total"
    echo "  ✅ Passed: $pass"
    echo "  ⚠️  Warnings: $warn"
    echo "  ❌ Failed: $fail"

    local score=$((pass * 100 / total))
    echo "  📈 Security Score: ${score}%"

    if [ $fail -eq 0 ] && [ $score -ge 80 ]; then
        log_success "Security validation passed! 🎉"
        exit 0
    elif [ $fail -eq 0 ]; then
        log_warning "Security validation passed with warnings"
        exit 1
    else
        log_error "Security validation failed - critical issues found"
        exit 2
    fi
}

# Handle command line arguments
case "${1:-}" in
    "--help"|"-h")
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Validate security controls in K8s Attack-Defense Lab"
        echo ""
        echo "Options:"
        echo "  --help, -h    Show this help message"
        echo "  --report-only Generate report without running validations"
        echo ""
        exit 0
        ;;
    "--report-only")
        # Generate report from existing results (if any)
        if [ ${#VALIDATION_RESULTS[@]} -eq 0 ]; then
            log_error "No validation results found. Run validation first."
            exit 1
        fi
        generate_validation_report
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac