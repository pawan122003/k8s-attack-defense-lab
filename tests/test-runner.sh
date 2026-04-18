#!/bin/bash

# Test Runner: Execute all attack scenario tests
# Generates comprehensive validation report

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
declare -A TEST_RESULTS
declare -A TEST_DETAILS

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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please install kubectl."
        exit 1
    fi

    # Check if cluster is accessible
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot access Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi

    # Check if test scenarios exist
    if [ ! -d "$SCRIPT_DIR/scenarios" ]; then
        log_error "Test scenarios directory not found: $SCRIPT_DIR/scenarios"
        exit 1
    fi

    log_success "Prerequisites check passed"
}

# Discover test files
discover_tests() {
    log_info "Discovering test scenarios..."

    # Find all test scripts
    TEST_FILES=($(find "$SCRIPT_DIR/scenarios" -name "test-*.sh" -type f | sort))

    if [ ${#TEST_FILES[@]} -eq 0 ]; then
        log_error "No test files found in $SCRIPT_DIR/scenarios"
        exit 1
    fi

    log_success "Found ${#TEST_FILES[@]} test scenarios"
    for test_file in "${TEST_FILES[@]}"; do
        echo "  - $(basename "$test_file")"
    done
}

# Run single test
run_test() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .sh)

    log_info "Running test: $test_name"

    # Create temporary log file
    local log_file="/tmp/test-${test_name}.log"

    # Run test and capture output
    if bash "$test_file" > "$log_file" 2>&1; then
        local exit_code=$?
        case $exit_code in
            0) TEST_RESULTS[$test_name]="PASS" ;;
            1) TEST_RESULTS[$test_name]="PARTIAL" ;;
            2) TEST_RESULTS[$test_name]="FAIL" ;;
            *) TEST_RESULTS[$test_name]="ERROR" ;;
        esac
    else
        local exit_code=$?
        case $exit_code in
            0) TEST_RESULTS[$test_name]="PASS" ;;
            1) TEST_RESULTS[$test_name]="PARTIAL" ;;
            2) TEST_RESULTS[$test_name]="FAIL" ;;
            *) TEST_RESULTS[$test_name]="ERROR" ;;
        esac
    fi

    # Store test output
    TEST_DETAILS[$test_name]=$(cat "$log_file")

    # Clean up log file
    rm -f "$log_file"

    log_success "Test $test_name completed: ${TEST_RESULTS[$test_name]}"
}

# Run all tests
run_all_tests() {
    log_info "Starting test execution..."

    local total_tests=${#TEST_FILES[@]}
    local completed=0

    for test_file in "${TEST_FILES[@]}"; do
        ((completed++))
        log_info "Progress: $completed/$total_tests"

        run_test "$test_file"

        # Small delay between tests
        sleep 2
    done

    log_success "All tests completed"
}

# Generate test report
generate_report() {
    local report_file="$SCRIPT_DIR/test-report-$(date +%Y%m%d-%H%M%S).md"
    local total_tests=${#TEST_RESULTS[@]}
    local pass_count=0
    local partial_count=0
    local fail_count=0
    local error_count=0

    # Count results
    for result in "${TEST_RESULTS[@]}"; do
        case $result in
            "PASS") ((pass_count++)) ;;
            "PARTIAL") ((partial_count++)) ;;
            "FAIL") ((fail_count++)) ;;
            "ERROR") ((error_count++)) ;;
        esac
    done

    # Calculate percentages
    local pass_percent=$((pass_count * 100 / total_tests))
    local partial_percent=$((partial_count * 100 / total_tests))
    local fail_percent=$((fail_count * 100 / total_tests))

    # Generate report
    cat > "$report_file" << EOF
# K8s Attack-Defense Lab - Test Report

**Generated:** $(date)  
**Total Tests:** $total_tests  
**Test Environment:** $(kubectl config current-context)

## Summary

| Status | Count | Percentage |
|--------|-------|------------|
| ✅ PASS | $pass_count | ${pass_percent}% |
| ⚠️  PARTIAL | $partial_count | ${partial_percent}% |
| ❌ FAIL | $fail_count | ${fail_percent}% |
| 💥 ERROR | $error_count | 0% |

## Test Results

EOF

    # Add individual test results
    for test_name in "${!TEST_RESULTS[@]}"; do
        local result=${TEST_RESULTS[$test_name]}
        local status_icon=""
        case $result in
            "PASS") status_icon="✅" ;;
            "PARTIAL") status_icon="⚠️" ;;
            "FAIL") status_icon="❌" ;;
            "ERROR") status_icon="💥" ;;
        esac

        cat >> "$report_file" << EOF
### $status_icon $test_name

**Status:** $result

**Details:**
\`\`\`
${TEST_DETAILS[$test_name]}
\`\`\`

---

EOF
    done

    # Add recommendations
    cat >> "$report_file" << EOF

## Recommendations

EOF

    if [ $fail_count -gt 0 ]; then
        cat >> "$report_file" << EOF
### Critical Issues
- $fail_count tests failed. Review failed tests and fix underlying issues.
- Check that all attack scenarios are properly implemented.
- Verify defense mechanisms are correctly deployed.

EOF
    fi

    if [ $partial_count -gt 0 ]; then
        cat >> "$report_file" << EOF
### Partial Success
- $partial_count tests had partial success. Some defenses may be missing or misconfigured.
- Review partial tests to identify gaps in security controls.

EOF
    fi

    if [ $pass_count -eq $total_tests ]; then
        cat >> "$report_file" << EOF
### Excellent Results
- All tests passed! The lab is fully functional with comprehensive attack and defense coverage.

EOF
    fi

    cat >> "$report_file" << EOF
## Next Steps

1. **Review Failed Tests**: Address any failing scenarios
2. **Tune Defenses**: Adjust detection rules based on test results
3. **Add More Tests**: Consider adding tests for edge cases
4. **Performance Testing**: Test under load conditions
5. **Integration Testing**: Test with real CI/CD pipelines

## Test Environment Info

\`\`\`bash
# Cluster info
$(kubectl cluster-info)

# Node info
$(kubectl get nodes -o wide)

# Version info
$(kubectl version --short)
\`\`\`
EOF

    log_success "Test report generated: $report_file"
    echo "📄 Report saved to: $report_file"
}

# Main execution
main() {
    echo "🧪 K8s Attack-Defense Lab - Test Runner"
    echo "========================================"

    check_prerequisites
    discover_tests
    run_all_tests
    generate_report

    echo ""
    log_success "Test execution completed"

    # Summary
    local total=${#TEST_RESULTS[@]}
    local pass=$(grep -c "PASS" <<< "${TEST_RESULTS[*]}")
    local partial=$(grep -c "PARTIAL" <<< "${TEST_RESULTS[*]}")
    local fail=$(grep -c "FAIL" <<< "${TEST_RESULTS[*]}")

    echo ""
    echo "📊 Final Summary:"
    echo "  Total Tests: $total"
    echo "  ✅ Passed: $pass"
    echo "  ⚠️  Partial: $partial"
    echo "  ❌ Failed: $fail"

    if [ $fail -eq 0 ] && [ $partial -eq 0 ]; then
        log_success "All tests passed! 🎉"
        exit 0
    elif [ $fail -eq 0 ]; then
        log_warning "Some tests had partial success. Review results."
        exit 1
    else
        log_error "Some tests failed. Check the report for details."
        exit 2
    fi
}

# Handle command line arguments
case "${1:-}" in
    "--help"|"-h")
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Run comprehensive tests for K8s Attack-Defense Lab scenarios"
        echo ""
        echo "Options:"
        echo "  --help, -h    Show this help message"
        echo "  --list        List available test scenarios"
        echo "  --run TEST    Run specific test (e.g., --run test-supply-chain-poisoned-image)"
        echo ""
        exit 0
        ;;
    "--list")
        discover_tests
        exit 0
        ;;
    "--run")
        if [ -z "$2" ]; then
            log_error "Please specify a test name"
            exit 1
        fi
        test_file="$SCRIPT_DIR/scenarios/$2.sh"
        if [ ! -f "$test_file" ]; then
            log_error "Test file not found: $test_file"
            exit 1
        fi
        run_test "$test_file"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac