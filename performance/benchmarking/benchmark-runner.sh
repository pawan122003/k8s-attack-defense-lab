#!/bin/bash

# Kubernetes Security Lab Performance Benchmarking
# Measures performance impact of security controls

set -e

echo "📊 KUBERNETES SECURITY PERFORMANCE BENCHMARKING"
echo "==============================================="

RESULTS_DIR="benchmark-results-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RESULTS_DIR"

# Function to measure API response times
measure_api_performance() {
    local test_name="$1"
    local command="$2"
    local iterations="${3:-100}"

    echo "Measuring $test_name performance..."

    local start_time=$(date +%s%N)
    for i in $(seq 1 $iterations); do
        eval "$command" > /dev/null 2>&1
    done
    local end_time=$(date +%s%N)

    local total_time=$((end_time - start_time))
    local avg_time=$((total_time / iterations / 1000000))  # Convert to milliseconds

    echo "$test_name: ${avg_time}ms average response time" >> "$RESULTS_DIR/api-performance.txt"
}

# Function to measure resource usage
measure_resource_usage() {
    local test_name="$1"
    local duration="${2:-60}"

    echo "Measuring resource usage for $test_name..."

    # Start resource monitoring
    kubectl top nodes --no-headers | awk '{print $1","$2","$3","$4","$5}' > "$RESULTS_DIR/${test_name}-nodes-before.csv"
    kubectl top pods --all-namespaces --no-headers | awk '{print $1","$2","$3","$4}' > "$RESULTS_DIR/${test_name}-pods-before.csv"

    sleep $duration

    kubectl top nodes --no-headers | awk '{print $1","$2","$3","$4","$5}' > "$RESULTS_DIR/${test_name}-nodes-after.csv"
    kubectl top pods --all-namespaces --no-headers | awk '{print $1","$2","$3","$4}' > "$RESULTS_DIR/${test_name}-pods-after.csv"
}

# Function to measure security control overhead
measure_security_overhead() {
    echo "Measuring security control performance overhead..."

    # Baseline: No security controls
    echo "Testing baseline (no security)..."
    measure_api_performance "baseline-pod-list" "kubectl get pods --all-namespaces" 50
    measure_resource_usage "baseline" 30

    # With Falco
    echo "Testing with Falco..."
    kubectl apply -f monitors/falco/ 2>/dev/null || true
    sleep 10
    measure_api_performance "with-falco-pod-list" "kubectl get pods --all-namespaces" 50
    measure_resource_usage "with-falco" 30

    # With Kyverno
    echo "Testing with Kyverno..."
    kubectl apply -f defenses/admission/kyverno/ 2>/dev/null || true
    sleep 10
    measure_api_performance "with-kyverno-pod-list" "kubectl get pods --all-namespaces" 50
    measure_resource_usage "with-kyverno" 30

    # With Network Policies
    echo "Testing with Network Policies..."
    kubectl apply -f defenses/network/ 2>/dev/null || true
    sleep 10
    measure_api_performance "with-netpol-pod-list" "kubectl get pods --all-namespaces" 50
    measure_resource_usage "with-netpol" 30
}

# Function to benchmark attack detection
benchmark_attack_detection() {
    echo "Benchmarking attack detection performance..."

    local attack_scenarios=(
        "attacks/supply-chain/poisoned-image.yaml"
        "attacks/lateral-movement/serviceaccount-theft.yaml"
        "attacks/persistence/cronjob-backdoor.yaml"
        "attacks/dos/api-server-watch-spam.yaml"
    )

    for attack in "${attack_scenarios[@]}"; do
        if [ -f "$attack" ]; then
            local attack_name=$(basename "$attack" .yaml)
            echo "Testing $attack_name detection..."

            # Deploy attack
            local deploy_start=$(date +%s%N)
            kubectl apply -f "$attack" 2>/dev/null || true
            local deploy_end=$(date +%s%N)

            # Wait for detection
            local detect_start=$(date +%s%N)
            sleep 30  # Allow time for detection
            local detect_end=$(date +%s%N)

            # Check if detected
            local detected=false
            if kubectl logs -n falco daemonset/falco --tail=100 | grep -i "$attack_name\|attack\|security" > /dev/null 2>&1; then
                detected=true
            fi

            # Calculate times
            local deploy_time=$((deploy_end - deploy_start))
            local detect_time=$((detect_end - detect_start))

            echo "$attack_name,${deploy_time},$detect_time,$detected" >> "$RESULTS_DIR/attack-detection.csv"

            # Cleanup
            kubectl delete -f "$attack" 2>/dev/null || true
            sleep 5
        fi
    done
}

# Main benchmarking execution
echo "Starting comprehensive performance benchmarking..."
echo "Results will be saved to: $RESULTS_DIR"

# Run benchmarks
measure_security_overhead
benchmark_attack_detection

# Generate summary report
cat > "$RESULTS_DIR/benchmark-summary.md" << SUMMARY_EOF
# Kubernetes Security Lab Performance Benchmark Results

Generated on: $(date)

## Executive Summary

This report contains performance benchmarking results for the Kubernetes Attack-Defense Lab security controls.

## Test Environment

- Kubernetes Version: $(kubectl version --short 2>/dev/null | grep Server | cut -d: -f2 | tr -d ' ')
- Node Count: $(kubectl get nodes --no-headers | wc -l)
- Security Controls: Falco, Kyverno, Network Policies, RBAC

## Key Findings

### Security Control Overhead

SUMMARY_EOF

# Add performance data to summary
if [ -f "$RESULTS_DIR/api-performance.txt" ]; then
    echo "" >> "$RESULTS_DIR/benchmark-summary.md"
    echo "### API Performance Impact" >> "$RESULTS_DIR/benchmark-summary.md"
    echo "" >> "$RESULTS_DIR/benchmark-summary.md"
    cat "$RESULTS_DIR/api-performance.txt" >> "$RESULTS_DIR/benchmark-summary.md"
fi

if [ -f "$RESULTS_DIR/attack-detection.csv" ]; then
    echo "" >> "$RESULTS_DIR/benchmark-summary.md"
    echo "### Attack Detection Performance" >> "$RESULTS_DIR/benchmark-summary.md"
    echo "" >> "$RESULTS_DIR/benchmark-summary.md"
    echo "| Attack Scenario | Deployment Time (ns) | Detection Time (ns) | Detected |" >> "$RESULTS_DIR/benchmark-summary.md"
    echo "|-----------------|---------------------|-------------------|----------|" >> "$RESULTS_DIR/benchmark-summary.md"
    while IFS=',' read -r attack deploy_time detect_time detected; do
        echo "| $attack | $deploy_time | $detect_time | $detected |" >> "$RESULTS_DIR/benchmark-summary.md"
    done < "$RESULTS_DIR/attack-detection.csv"
fi

echo "" >> "$RESULTS_DIR/benchmark-summary.md"
echo "## Recommendations" >> "$RESULTS_DIR/benchmark-summary.md"
echo "" >> "$RESULTS_DIR/benchmark-summary.md"
echo "Based on the benchmark results, consider the following optimizations:" >> "$RESULTS_DIR/benchmark-summary.md"
echo "" >> "$RESULTS_DIR/benchmark-summary.md"
echo "1. **Resource Allocation**: Adjust resource limits based on observed usage patterns" >> "$RESULTS_DIR/benchmark-summary.md"
echo "2. **Detection Tuning**: Fine-tune Falco rules for better performance/detection balance" >> "$RESULTS_DIR/benchmark-summary.md"
echo "3. **Caching**: Implement caching for frequently accessed security policies" >> "$RESULTS_DIR/benchmark-summary.md"
echo "4. **Monitoring**: Set up continuous performance monitoring in production" >> "$RESULTS_DIR/benchmark-summary.md"

echo "Benchmarking complete! Results saved to: $RESULTS_DIR"
echo "Summary report: $RESULTS_DIR/benchmark-summary.md"
SUMMARY_EOF

chmod +x performance/benchmarking/benchmark-runner.sh

# 3. Resource Optimization
echo "🔧 Creating resource optimization configurations..."
cat > performance/optimization/hpa-config.yaml << 'EOF'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: falco-hpa
  namespace: falco
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: DaemonSet
    name: falco
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: kyverno-hpa
  namespace: kyverno
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: kyverno-admission-controller
  minReplicas: 2
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: prometheus-hpa
  namespace: monitoring
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: prometheus
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 75
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 85
