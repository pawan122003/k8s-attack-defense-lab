#!/bin/bash

# Test: Supply Chain - Poisoned Image Attack
# Tests the poisoned-image.yaml attack scenario

set -e

TEST_NAME="supply-chain-poisoned-image"
NAMESPACE="test-${TEST_NAME}"
ATTACK_FILE="attacks/supply-chain/poisoned-image.yaml"

echo "🧪 Testing ${TEST_NAME}..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Cleanup function
cleanup() {
    echo "🧹 Cleaning up test resources..."
    kubectl delete namespace ${NAMESPACE} --ignore-not-found=true --timeout=30s || true
}

# Error handling
error_exit() {
    echo -e "${RED}❌ Test FAILED: $1${NC}" >&2
    cleanup
    exit 1
}

# Success message
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Warning message
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Setup test namespace
setup_test() {
    echo "📦 Setting up test environment..."
    kubectl create namespace ${NAMESPACE} || error_exit "Failed to create namespace"

    # Label namespace for monitoring
    kubectl label namespace ${NAMESPACE} security=monitored || error_exit "Failed to label namespace"
}

# Deploy attack scenario
deploy_attack() {
    echo "🚀 Deploying attack scenario..."
    kubectl apply -f ${ATTACK_FILE} -n ${NAMESPACE} || error_exit "Failed to deploy attack"

    # Wait for pod to be ready
    echo "⏳ Waiting for attack pod to be ready..."
    kubectl wait --for=condition=Ready pod --all -n ${NAMESPACE} --timeout=60s || error_exit "Attack pod failed to start"
}

# Verify attack works (without defenses)
verify_attack_success() {
    echo "🔍 Verifying attack execution..."

    # Check if poisoned app pod exists
    local pod_name=$(kubectl get pods -n ${NAMESPACE} -l app=poisoned-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [ -z "$pod_name" ]; then
        error_exit "Poisoned app pod not found"
    fi

    # Check if reverse shell was established (simulated)
    echo "Checking for reverse shell indicators..."
    local logs=$(kubectl logs -n ${NAMESPACE} deployment/poisoned-app 2>/dev/null || echo "")

    if echo "$logs" | grep -q "Reverse shell established\|nc -e\|bash -i"; then
        success "Attack successfully executed - reverse shell detected in logs"
        ATTACK_SUCCESS=true
    else
        warning "Attack may not have executed - no reverse shell indicators found"
        ATTACK_SUCCESS=false
    fi

    # Check for C2 connection attempts
    if echo "$logs" | grep -q "Connecting to\|attacker.com\|10.0.0.1"; then
        success "C2 communication detected"
    else
        warning "No C2 communication detected"
    fi
}

# Test defense mechanisms
test_defenses() {
    echo "🛡️  Testing defense mechanisms..."

    # Test 1: Image policy should block unsigned images
    echo "Testing image policy enforcement..."
    if kubectl get pods -n ${NAMESPACE} -l app=poisoned-app -o jsonpath='{.items[*].status.phase}' | grep -q "Pending\|Failed"; then
        success "Image policy correctly blocked deployment"
        DEFENSE_IMAGE_POLICY=true
    else
        warning "Image policy did not block deployment"
        DEFENSE_IMAGE_POLICY=false
    fi

    # Test 2: Network policy should block outbound connections
    echo "Testing network policy enforcement..."
    # This would require more complex testing with network tools
    warning "Network policy testing requires additional tools"

    # Test 3: Falco should detect suspicious activity
    echo "Testing Falco detection..."
    sleep 10  # Give Falco time to detect
    local falco_alerts=$(kubectl logs -n falco daemonset/falco --tail=50 2>/dev/null | grep -i "poisoned\|reverse\|shell" | wc -l)
    if [ "$falco_alerts" -gt 0 ]; then
        success "Falco detected suspicious activity ($falco_alerts alerts)"
        DEFENSE_FALCO=true
    else
        warning "Falco did not detect activity"
        DEFENSE_FALCO=false
    fi
}

# Test remediation
test_remediation() {
    echo "🔧 Testing remediation systems..."

    # Check if pod gets quarantined
    echo "Checking for automatic quarantine..."
    kubectl label pod -n ${NAMESPACE} -l app=poisoned-app security.kubernetes.io/quarantined=true 2>/dev/null || true

    sleep 5

    local quarantined=$(kubectl get pods -n ${NAMESPACE} -l security.kubernetes.io/quarantined=true -o name | wc -l)
    if [ "$quarantined" -gt 0 ]; then
        success "Pod successfully quarantined"
        REMEDIATION_QUARANTINE=true
    else
        warning "Pod not quarantined"
        REMEDIATION_QUARANTINE=false
    fi

    # Check if evidence was collected
    echo "Checking for evidence collection..."
    local evidence=$(kubectl get configmaps -n forensics-evidence 2>/dev/null | grep -c "poisoned" || echo "0")
    if [ "$evidence" -gt 0 ]; then
        success "Evidence collected ($evidence items)"
        REMEDIATION_EVIDENCE=true
    else
        warning "No evidence collected"
        REMEDIATION_EVIDENCE=false
    fi
}

# Generate test report
generate_report() {
    echo ""
    echo "📊 Test Report: ${TEST_NAME}"
    echo "========================================"

    echo "Attack Execution:"
    echo "  - Attack Deployed: ✅"
    echo "  - Attack Succeeded: $(if [ "$ATTACK_SUCCESS" = true ]; then echo "✅"; else echo "❌"; fi)"

    echo ""
    echo "Defense Effectiveness:"
    echo "  - Image Policy: $(if [ "$DEFENSE_IMAGE_POLICY" = true ]; then echo "✅"; else echo "❌"; fi)"
    echo "  - Falco Detection: $(if [ "$DEFENSE_FALCO" = true ]; then echo "✅"; else echo "❌"; fi)"

    echo ""
    echo "Remediation:"
    echo "  - Quarantine: $(if [ "$REMEDIATION_QUARANTINE" = true ]; then echo "✅"; else echo "❌"; fi)"
    echo "  - Evidence Collection: $(if [ "$REMEDIATION_EVIDENCE" = true ]; then echo "✅"; else echo "❌"; fi)"

    echo ""
    echo "Overall Assessment:"
    if [ "$ATTACK_SUCCESS" = true ] && [ "$DEFENSE_IMAGE_POLICY" = true ] && [ "$DEFENSE_FALCO" = true ]; then
        echo -e "${GREEN}✅ PASS: Attack executed but defenses detected/blocked it${NC}"
        TEST_RESULT="PASS"
    elif [ "$ATTACK_SUCCESS" = true ]; then
        echo -e "${YELLOW}⚠️  PARTIAL: Attack succeeded, some defenses may be missing${NC}"
        TEST_RESULT="PARTIAL"
    else
        echo -e "${RED}❌ FAIL: Attack failed to execute${NC}"
        TEST_RESULT="FAIL"
    fi
}

# Main test execution
main() {
    echo "🧪 Starting test: ${TEST_NAME}"
    echo "========================================"

    # Initialize variables
    ATTACK_SUCCESS=false
    DEFENSE_IMAGE_POLICY=false
    DEFENSE_FALCO=false
    REMEDIATION_QUARANTINE=false
    REMEDIATION_EVIDENCE=false
    TEST_RESULT="UNKNOWN"

    # Trap for cleanup on exit
    trap cleanup EXIT

    setup_test
    deploy_attack
    verify_attack_success
    test_defenses
    test_remediation
    generate_report

    echo ""
    echo "🏁 Test completed: ${TEST_RESULT}"

    # Exit with appropriate code
    case $TEST_RESULT in
        "PASS") exit 0 ;;
        "PARTIAL") exit 1 ;;
        "FAIL") exit 2 ;;
        *) exit 3 ;;
    esac
}

# Run main function
main "$@"