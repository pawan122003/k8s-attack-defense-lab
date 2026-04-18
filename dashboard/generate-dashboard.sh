#!/bin/bash

# K8s Attack-Defense Lab Scoring Dashboard
# Generates comprehensive reports and scoring metrics

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
DASHBOARD_VERSION="1.0"
GENERATION_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# Scoring weights
PREVENTION_WEIGHT=40
DETECTION_WEIGHT=30
RESPONSE_WEIGHT=20
HARDENING_WEIGHT=10

# Initialize metrics
declare -A METRICS
declare -A SCORES

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_header() {
    echo -e "${PURPLE}🔥 $1${NC}"
}

log_metric() {
    echo -e "${CYAN}📊 $1${NC}"
}

# Collect test results
collect_test_results() {
    log_info "Collecting test results..."

    # Run test suite if not already run
    shopt -s nullglob
    test_reports=("$PROJECT_ROOT"/tests/test-report-*.md)
    shopt -u nullglob

    if [ ${#test_reports[@]} -eq 0 ]; then
        log_info "Running test suite..."
        bash "$PROJECT_ROOT/tests/test-runner.sh" > /dev/null 2>&1
        shopt -s nullglob
        test_reports=("$PROJECT_ROOT"/tests/test-report-*.md)
        shopt -u nullglob
    fi

    # Parse latest test report
    LATEST_REPORT=$(ls -t "${test_reports[@]}" 2>/dev/null | head -1)

    if [ -f "$LATEST_REPORT" ]; then
        # Extract test counts
        METRICS[TESTS_TOTAL]=$(grep "Total Tests:" "$LATEST_REPORT" | awk '{print $3}' || echo "0")
        METRICS[TESTS_PASS]=$(grep "PASS" "$LATEST_REPORT" | wc -l)
        METRICS[TESTS_PARTIAL]=$(grep "PARTIAL" "$LATEST_REPORT" | wc -l)
        METRICS[TESTS_FAIL]=$(grep "FAIL" "$LATEST_REPORT" | wc -l)
    else
        log_warning "No test reports found"
        METRICS[TESTS_TOTAL]=0
        METRICS[TESTS_PASS]=0
        METRICS[TESTS_PARTIAL]=0
        METRICS[TESTS_FAIL]=0
    fi
}

# Collect defense validation results
collect_defense_metrics() {
    log_info "Collecting defense validation metrics..."

    # Run validation if not already run
    shopt -s nullglob
    validation_reports=("$PROJECT_ROOT"/tests/validation-report-*.md)
    shopt -u nullglob

    if [ ${#validation_reports[@]} -eq 0 ]; then
        log_info "Running defense validation..."
        bash "$PROJECT_ROOT/tests/validators/validate-defenses.sh" > /dev/null 2>&1
        shopt -s nullglob
        validation_reports=("$PROJECT_ROOT"/tests/validation-report-*.md)
        shopt -u nullglob
    fi

    # Parse latest validation report
    LATEST_VALIDATION=$(ls -t "${validation_reports[@]}" 2>/dev/null | head -1)

    if [ -f "$LATEST_VALIDATION" ]; then
        # Extract validation results
        METRICS[VALIDATION_CHECKS]=$(grep "Total Checks:" "$LATEST_VALIDATION" | awk '{print $3}' || echo "0")
        METRICS[VALIDATION_PASS]=$(grep -c "PASS:" "$LATEST_VALIDATION" || echo "0")
        METRICS[VALIDATION_WARN]=$(grep -c "WARN:" "$LATEST_VALIDATION" || echo "0")
        METRICS[VALIDATION_FAIL]=$(grep -c "FAIL:" "$LATEST_VALIDATION" || echo "0")

        # Extract security score
        SECURITY_SCORE_LINE=$(grep "Security Score:" "$LATEST_VALIDATION" || echo "")
        METRICS[SECURITY_SCORE]=$(echo "$SECURITY_SCORE_LINE" | grep -o '[0-9]\+' | head -1 || echo "0")
    else
        log_warning "No validation reports found"
        METRICS[VALIDATION_CHECKS]=0
        METRICS[VALIDATION_PASS]=0
        METRICS[VALIDATION_WARN]=0
        METRICS[VALIDATION_FAIL]=0
        METRICS[SECURITY_SCORE]=0
    fi
}

# Collect cluster health metrics
collect_cluster_metrics() {
    log_info "Collecting cluster health metrics..."

    # Node status
    METRICS[NODES_TOTAL]=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    METRICS[NODES_READY]=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready")

    # Pod status
    METRICS[PODS_TOTAL]=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | wc -l)
    METRICS[PODS_RUNNING]=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | grep -c " Running")
    METRICS[PODS_FAILED]=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | grep -c " Failed\|CrashLoopBackOff")

    # Security-relevant metrics
    METRICS[PRIVILEGED_PODS]=$(kubectl get pods --all-namespaces -o jsonpath='{range .items[?(@.spec.securityContext.privileged)]}{.metadata.name}{"\n"}{end}' 2>/dev/null | wc -l)
    METRICS[DEFAULT_SA_PODS]=$(kubectl get pods --all-namespaces -o jsonpath='{range .items[?(@.spec.serviceAccountName=="default")]}{.metadata.name}{"\n"}{end}' 2>/dev/null | wc -l)
    METRICS[HOSTPATH_PODS]=$(kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.spec.volumes[?(@.hostPath)].hostPath.path}{"\n"}{end}' 2>/dev/null | wc -l)

    # Falco status
    METRICS[FALCO_RUNNING]=$(kubectl get pods -n falco --no-headers 2>/dev/null | grep -c " Running" || echo "0")

    # Remediation status
    METRICS[QUARANTINED_PODS]=$(kubectl get pods --all-namespaces -l security.kubernetes.io/quarantined=true --no-headers 2>/dev/null | wc -l)
    METRICS[EVIDENCE_ITEMS]=$(kubectl get configmaps -n forensics-evidence --no-headers 2>/dev/null | wc -l)
}

# Collect attack scenario metrics
collect_attack_metrics() {
    log_info "Collecting attack scenario metrics..."

    # Count deployed scenarios
    METRICS[SUPPLY_CHAIN_DEPLOYED]=$(kubectl get pods -l attack-type=supply-chain --no-headers 2>/dev/null | wc -l)
    METRICS[LATERAL_MOVEMENT_DEPLOYED]=$(kubectl get pods -l attack-type=lateral-movement --no-headers 2>/dev/null | wc -l)
    METRICS[PERSISTENCE_DEPLOYED]=$(kubectl get pods -l attack-type=persistence --no-headers 2>/dev/null | wc -l)
    METRICS[DOS_DEPLOYED]=$(kubectl get pods -l attack-type=dos --no-headers 2>/dev/null | wc -l)

    # Total scenarios
    METRICS[SCENARIOS_TOTAL]=15
    METRICS[SCENARIOS_DEPLOYED]=$((METRICS[SUPPLY_CHAIN_DEPLOYED] + METRICS[LATERAL_MOVEMENT_DEPLOYED] + METRICS[PERSISTENCE_DEPLOYED] + METRICS[DOS_DEPLOYED]))
}

# Calculate scores
calculate_scores() {
    log_info "Calculating performance scores..."

    # Test effectiveness score (0-100)
    if [ "${METRICS[TESTS_TOTAL]}" -gt 0 ]; then
        local test_pass_rate=$(( (METRICS[TESTS_PASS] * 100) / METRICS[TESTS_TOTAL] ))
        local test_partial_rate=$(( (METRICS[TESTS_PARTIAL] * 50) / METRICS[TESTS_TOTAL] ))
        SCORES[TEST_EFFECTIVENESS]=$((test_pass_rate + test_partial_rate))
    else
        SCORES[TEST_EFFECTIVENESS]=0
    fi

    # Defense score from validation
    SCORES[DEFENSE_SCORE]="${METRICS[SECURITY_SCORE]}"

    # Cluster health score (0-100)
    local node_health=0
    if [ "${METRICS[NODES_TOTAL]}" -gt 0 ]; then
        node_health=$(( (METRICS[NODES_READY] * 100) / METRICS[NODES_TOTAL] ))
    fi

    local pod_health=0
    if [ "${METRICS[PODS_TOTAL]}" -gt 0 ]; then
        pod_health=$(( (METRICS[PODS_RUNNING] * 100) / METRICS[PODS_TOTAL] ))
    fi

    SCORES[CLUSTER_HEALTH]=$(( (node_health + pod_health) / 2 ))

    # Security posture score (0-100)
    local security_issues=$((METRICS[PRIVILEGED_PODS] + METRICS[DEFAULT_SA_PODS] + METRICS[HOSTPATH_PODS]))
    if [ "$security_issues" -eq 0 ]; then
        SCORES[SECURITY_POSTURE]=100
    elif [ "$security_issues" -lt 5 ]; then
        SCORES[SECURITY_POSTURE]=75
    elif [ "$security_issues" -lt 10 ]; then
        SCORES[SECURITY_POSTURE]=50
    else
        SCORES[SECURITY_POSTURE]=25
    fi

    # Overall lab readiness score (0-100)
    local readiness_components=(
        $((SCORES[TEST_EFFECTIVENESS] * 30 / 100))
        $((SCORES[DEFENSE_SCORE] * 25 / 100))
        $((SCORES[CLUSTER_HEALTH] * 20 / 100))
        $((SCORES[SECURITY_POSTURE] * 15 / 100))
        $((METRICS[SCENARIOS_DEPLOYED] * 10 / METRICS[SCENARIOS_TOTAL]))
    )

    SCORES[LAB_READINESS]=0
    for component in "${readiness_components[@]}"; do
        SCORES[LAB_READINESS]=$((SCORES[LAB_READINESS] + component))
    done
}

# Generate dashboard report
generate_dashboard() {
    local report_file="$SCRIPT_DIR/dashboard-report-$(date +%Y%m%d-%H%M%S).md"

    cat > "$report_file" << EOF
# K8s Attack-Defense Lab Dashboard

**Version:** $DASHBOARD_VERSION  
**Generated:** $GENERATION_TIME  
**Cluster:** $(kubectl config current-context 2>/dev/null || echo "Unknown")

---

## 📊 Executive Summary

### Overall Lab Readiness Score
EOF

    # Add readiness score with visual indicator
    local readiness=${SCORES[LAB_READINESS]}
    local readiness_bar=""
    local readiness_color=""

    if [ $readiness -ge 90 ]; then
        readiness_bar="██████████"
        readiness_color="🟢"
    elif [ $readiness -ge 80 ]; then
        readiness_bar="████████░░"
        readiness_color="🟢"
    elif [ $readiness -ge 70 ]; then
        readiness_bar="██████░░░░"
        readiness_color="🟡"
    elif [ $readiness -ge 60 ]; then
        readiness_bar="████░░░░░░"
        readiness_color="🟡"
    elif [ $readiness -ge 50 ]; then
        readiness_bar="██░░░░░░░░"
        readiness_color="🟠"
    else
        readiness_bar="░░░░░░░░░░"
        readiness_color="🔴"
    fi

    cat >> "$report_file" << EOF
$readiness_color **${readiness}%** Ready  
\`$readiness_bar\` ($readiness/100)

### Key Metrics
- **Test Effectiveness:** ${SCORES[TEST_EFFECTIVENESS]}%
- **Defense Score:** ${SCORES[DEFENSE_SCORE]}%
- **Cluster Health:** ${SCORES[CLUSTER_HEALTH]}%
- **Security Posture:** ${SCORES[SECURITY_POSTURE]}%

---

## 🧪 Test Results

| Metric | Value |
|--------|-------|
| Total Tests | ${METRICS[TESTS_TOTAL]} |
| ✅ Passed | ${METRICS[TESTS_PASS]} |
| ⚠️  Partial | ${METRICS[TESTS_PARTIAL]} |
| ❌ Failed | ${METRICS[TESTS_FAIL]} |

**Test Effectiveness Score:** ${SCORES[TEST_EFFECTIVENESS]}%

---

## 🛡️ Defense Validation

| Metric | Value |
|--------|-------|
| Total Checks | ${METRICS[VALIDATION_CHECKS]} |
| ✅ Passed | ${METRICS[VALIDATION_PASS]} |
| ⚠️  Warnings | ${METRICS[VALIDATION_WARN]} |
| ❌ Failed | ${METRICS[VALIDATION_FAIL]} |

**Security Score:** ${METRICS[SECURITY_SCORE]}%

---

## ☸️ Cluster Health

### Node Status
- **Total Nodes:** ${METRICS[NODES_TOTAL]}
- **Ready Nodes:** ${METRICS[NODES_READY]}

### Pod Status
- **Total Pods:** ${METRICS[PODS_TOTAL]}
- **Running Pods:** ${METRICS[PODS_RUNNING]}
- **Failed Pods:** ${METRICS[PODS_FAILED]}

### Security Issues Detected
- **Privileged Pods:** ${METRICS[PRIVILEGED_PODS]}
- **Default SA Usage:** ${METRICS[DEFAULT_SA_PODS]}
- **Host Path Mounts:** ${METRICS[HOSTPATH_PODS]}

---

## 🎯 Attack Scenarios

| Category | Deployed | Status |
|----------|----------|--------|
| Supply Chain | ${METRICS[SUPPLY_CHAIN_DEPLOYED]} | $([ "${METRICS[SUPPLY_CHAIN_DEPLOYED]}" -gt 0 ] && echo "✅" || echo "❌") |
| Lateral Movement | ${METRICS[LATERAL_MOVEMENT_DEPLOYED]} | $([ "${METRICS[LATERAL_MOVEMENT_DEPLOYED]}" -gt 0 ] && echo "✅" || echo "❌") |
| Persistence | ${METRICS[PERSISTENCE_DEPLOYED]} | $([ "${METRICS[PERSISTENCE_DEPLOYED]}" -gt 0 ] && echo "✅" || echo "❌") |
| DoS | ${METRICS[DOS_DEPLOYED]} | $([ "${METRICS[DOS_DEPLOYED]}" -gt 0 ] && echo "✅" || echo "❌") |

**Total Scenarios:** ${METRICS[SCENARIOS_DEPLOYED]}/${METRICS[SCENARIOS_TOTAL]}

---

## 🔍 Monitoring Status

### Runtime Security
- **Falco Pods Running:** ${METRICS[FALCO_RUNNING]}

### Incident Response
- **Quarantined Pods:** ${METRICS[QUARANTINED_PODS]}
- **Evidence Items:** ${METRICS[EVIDENCE_ITEMS]}

---

## 📈 Trends & Recommendations

EOF

    # Add recommendations based on scores
    if [ ${SCORES[LAB_READINESS]} -ge 80 ]; then
        cat >> "$report_file" << EOF
### 🎉 Excellent Status
Your lab is well-configured and ready for advanced exercises!

**Recommendations:**
- Run red team exercises with complex attack chains
- Test incident response procedures
- Consider adding custom attack scenarios
- Participate in capture-the-flag competitions

EOF
    elif [ ${SCORES[LAB_READINESS]} -ge 60 ]; then
        cat >> "$report_file" << EOF
### ✅ Good Progress
Your lab has solid foundations with room for improvement.

**Recommendations:**
- Address any failed validation checks
- Deploy remaining attack scenarios
- Fine-tune detection rules
- Practice basic incident response

EOF
    else
        cat >> "$report_file" << EOF
### ⚠️ Needs Attention
Your lab needs significant improvements before advanced use.

**Critical Issues to Address:**
- Fix failed validation checks (see validation report)
- Deploy basic security controls
- Ensure cluster stability
- Complete fundamental configurations

EOF
    fi

    cat >> "$report_file" << EOF
### Performance Insights

**Test Effectiveness (${SCORES[TEST_EFFECTIVENESS]}%):**
EOF

    if [ ${SCORES[TEST_EFFECTIVENESS]} -ge 80 ]; then
        echo "- Excellent test results - attacks and defenses working well" >> "$report_file"
    elif [ ${SCORES[TEST_EFFECTIVENESS]} -ge 60 ]; then
        echo "- Good test coverage with some areas needing attention" >> "$report_file"
    else
        echo "- Significant test failures - review and fix scenarios" >> "$report_file"
    fi

    cat >> "$report_file" << EOF

**Defense Score (${SCORES[DEFENSE_SCORE]}%):**
EOF

    if [ ${SCORES[DEFENSE_SCORE]} -ge 80 ]; then
        echo "- Strong security controls implemented" >> "$report_file"
    elif [ ${SCORES[DEFENSE_SCORE]} -ge 60 ]; then
        echo "- Adequate defenses with improvement opportunities" >> "$report_file"
    else
        echo "- Critical security gaps need immediate attention" >> "$report_file"
    fi

    cat >> "$report_file" << EOF

**Cluster Health (${SCORES[CLUSTER_HEALTH]}%):**
EOF

    if [ ${SCORES[CLUSTER_HEALTH]} -ge 95 ]; then
        echo "- Cluster operating optimally" >> "$report_file"
    elif [ ${SCORES[CLUSTER_HEALTH]} -ge 80 ]; then
        echo "- Minor cluster issues to address" >> "$report_file"
    else
        echo "- Significant cluster health problems" >> "$report_file"
    fi

    cat >> "$report_file" << EOF

---

## 📋 Action Items

### Immediate (Next 1-2 days)
EOF

    # Generate action items based on metrics
    if [ ${METRICS[VALIDATION_FAIL]} -gt 0 ]; then
        echo "- Fix ${METRICS[VALIDATION_FAIL]} failed validation checks" >> "$report_file"
    fi

    if [ ${METRICS[TESTS_FAIL]} -gt 0 ]; then
        echo "- Address ${METRICS[TESTS_FAIL]} failing tests" >> "$report_file"
    fi

    if [ ${METRICS[FALCO_RUNNING]} -eq 0 ]; then
        echo "- Deploy Falco for runtime security monitoring" >> "$report_file"
    fi

    if [ ${METRICS[SCENARIOS_DEPLOYED]} -lt 15 ]; then
        echo "- Deploy remaining attack scenarios (${METRICS[SCENARIOS_DEPLOYED]}/15 deployed)" >> "$report_file"
    fi

    cat >> "$report_file" << EOF

### Short Term (Next 1-2 weeks)
- Run comprehensive red team exercises
- Test incident response procedures
- Fine-tune alerting and monitoring
- Document lessons learned

### Long Term (Next 1-2 months)
- Develop custom attack scenarios
- Implement advanced defense techniques
- Set up automated compliance checks
- Build security training programs

---

## 🔧 Technical Details

**Generation Command:**
\`\`\`bash
./dashboard/generate-dashboard.sh
\`\`\`

**Data Sources:**
- Test reports from \`tests/test-runner.sh\`
- Validation reports from \`tests/validators/validate-defenses.sh\`
- Live cluster metrics via kubectl

**Report Retention:** 30 days (configurable)

---

*Generated by K8s Attack-Defense Lab Dashboard v$DASHBOARD_VERSION*
EOF

    log_success "Dashboard report generated: $report_file"
    echo "📄 Report saved to: $report_file"

    # Display summary on console
    echo ""
    log_header "Dashboard Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🏆 Lab Readiness Score: ${SCORES[LAB_READINESS]}%"
    echo "🧪 Test Effectiveness:  ${SCORES[TEST_EFFECTIVENESS]}%"
    echo "🛡️  Defense Score:      ${SCORES[DEFENSE_SCORE]}%"
    echo "☸️  Cluster Health:     ${SCORES[CLUSTER_HEALTH]}%"
    echo "🔒 Security Posture:   ${SCORES[SECURITY_POSTURE]}%"
    echo ""
    echo "📈 Scenarios Deployed: ${METRICS[SCENARIOS_DEPLOYED]}/${METRICS[SCENARIOS_TOTAL]}"
    echo "📊 Tests Passed:        ${METRICS[TESTS_PASS]}/${METRICS[TESTS_TOTAL]}"
    echo "✅ Validations Passed:  ${METRICS[VALIDATION_PASS]}/${METRICS[VALIDATION_CHECKS]}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Main execution
main() {
    echo "🎯 K8s Attack-Defense Lab Dashboard"
    echo "==================================="

    # Collect all metrics
    collect_test_results
    collect_defense_metrics
    collect_cluster_metrics
    collect_attack_metrics

    # Calculate scores
    calculate_scores

    # Generate dashboard
    generate_dashboard

    log_success "Dashboard generation completed"
}

# Handle command line arguments
case "${1:-}" in
    "--help"|"-h")
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Generate comprehensive dashboard for K8s Attack-Defense Lab"
        echo ""
        echo "Options:"
        echo "  --help, -h    Show this help message"
        echo "  --quiet, -q   Suppress console output"
        echo ""
        exit 0
        ;;
    "--quiet"|"-q")
        # Redirect stdout to /dev/null but keep stderr
        exec > /dev/null
        main "$@"
        ;;
    *)
        main "$@"
        ;;
esac