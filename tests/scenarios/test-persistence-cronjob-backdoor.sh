#!/bin/bash

# Test: Persistence - CronJob Backdoor
set -e

TEST_NAME="persistence-cronjob-backdoor"
NAMESPACE="test-${TEST_NAME}"
ATTACK_FILE="attacks/persistence/cronjob-backdoor.yaml"

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
    local cronjobs=$(kubectl get cronjobs -n ${NAMESPACE} -o name 2>/dev/null | wc -l)
    if [ "$cronjobs" -gt 0 ]; then
        echo "PASS: CronJob backdoor deployed successfully"
        return 0
    fi
    echo "FAIL: CronJob not deployed"
    return 1
}

main() {
    setup_test
    deploy_attack
    verify_attack
}

main "$@"