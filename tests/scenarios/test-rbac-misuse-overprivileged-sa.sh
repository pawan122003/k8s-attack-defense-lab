#!/bin/bash

# Test: RBAC Misuse - Overprivileged ServiceAccount
set -e

TEST_NAME="rbac-misuse-overprivileged-sa"
NAMESPACE="test-${TEST_NAME}"
ATTACK_FILE="attacks/rbac-misuse/overprivileged-sa.yaml"

echo "Testing ${TEST_NAME}..."

cleanup() {
    kubectl delete namespace ${NAMESPACE} --ignore-not-found=true --timeout=30s 2>/dev/null || true
    kubectl delete clusterrolebinding overprivileged-binding 2>/dev/null || true
    kubectl delete clusterrole overprivileged-role 2>/dev/null || true
}
trap cleanup EXIT

setup_test() {
    kubectl create namespace ${NAMESPACE} 2>/dev/null || true
}

deploy_attack() {
    kubectl apply -f ${ATTACK_FILE} 2>/dev/null || true
}

verify_attack() {
    local bindings=$(kubectl get clusterrolebinding -o name 2>/dev/null | grep -c "overprivileged" || echo "0")
    if [ "$bindings" -gt 0 ]; then
        echo "PASS: Overprivileged ClusterRoleBinding deployed"
        return 0
    fi
    echo "FAIL: RBAC abuse not deployed"
    return 1
}

main() {
    setup_test
    deploy_attack
    verify_attack
}

main "$@"