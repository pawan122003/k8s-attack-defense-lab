#!/bin/bash

# Test: DoS - PVC Exhaustion
set -e

TEST_NAME="dos-pvc-full"
NAMESPACE="test-${TEST_NAME}"
ATTACK_FILE="attacks/dos/pvc-full.yaml"

echo "Testing ${TEST_NAME}..."

cleanup() {
    kubectl delete namespace ${NAMESPACE} --ignore-not-found=true --timeout=30s 2>/dev/null || true
}
trap cleanup EXIT

setup_test() {
    kubectl create namespace ${NAMESPACE} 2>/dev/null || true
    kubectl label namespace ${NAMESPACE} security=monitored 2>/dev/null || true
}

deploy_attack() {
    kubectl apply -f ${ATTACK_FILE} -n ${NAMESPACE} 2>/dev/null || true
    kubectl wait --for=condition=Ready pod --all -n ${NAMESPACE} --timeout=90s 2>/dev/null || true
}

verify_attack() {
    local pvcs=$(kubectl get pvc -n ${NAMESPACE} -o name 2>/dev/null | wc -l)
    if [ "$pvcs" -gt 0 ] || kubectl get pods -n ${NAMESPACE} -o name 2>/dev/null | wc -l | grep -q "[1-9]"; then
        echo "PASS: Attack resources deployed successfully"
        return 0
    fi
    echo "FAIL: Attack not deployed"
    return 1
}

main() {
    setup_test
    deploy_attack
    verify_attack
}

main "$@"