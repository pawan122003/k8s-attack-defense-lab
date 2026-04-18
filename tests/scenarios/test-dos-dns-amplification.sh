#!/bin/bash

# Test: DoS - DNS Amplification
set -e

TEST_NAME="dos-dns-amplification"
NAMESPACE="test-${TEST_NAME}"
ATTACK_FILE="attacks/dos/dns-amplification.yaml"

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
    kubectl wait --for=condition=Ready pod --all -n ${NAMESPACE} --timeout=60s 2>/dev/null || true
}

verify_attack() {
    local pods=$(kubectl get pods -n ${NAMESPACE} -o name 2>/dev/null | wc -l)
    if [ "$pods" -gt 0 ]; then
        echo "PASS: Attack pod deployed successfully"
        return 0
    fi
    echo "FAIL: Attack pod not deployed"
    return 1
}

main() {
    setup_test
    deploy_attack
    verify_attack
}

main "$@"