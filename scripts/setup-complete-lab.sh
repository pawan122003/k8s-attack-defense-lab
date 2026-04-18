#!/bin/bash

# K8s Attack-Defense Lab - Complete Setup Script
# Sets up entire lab environment: cluster, tools, attacks, defenses, monitoring

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

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    local missing_tools=()

    for tool in kubectl kind helm; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Install from: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi

    if ! docker info &> /dev/null 2>&1 && ! podman info &> /dev/null 2>&1; then
        log_error "Docker or Podman is required"
        exit 1
    fi

    log_success "Prerequisites check passed"
}

# Setup Kind cluster
setup_cluster() {
    log_info "Setting up Kind cluster..."

    local cluster_name="attack-defense"

    if kind get clusters 2>/dev/null | grep -q "^${cluster_name}$"; then
        log_warning "Cluster '$cluster_name' already exists"
        read -p "Delete and recreate? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            kind delete cluster --name "$cluster_name"
        else
            log_info "Using existing cluster"
            return 0
        fi
    fi

    log_info "Creating cluster..."
    kind create cluster --name "$cluster_name" --config "$PROJECT_ROOT/cluster/kind-config.yaml"

    log_info "Waiting for cluster to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=120s || true

    log_success "Cluster created successfully"
}

# Install security tools
install_tools() {
    log_info "Installing security tools..."

    # Install Kyverno
    log_info "Installing Kyverno..."
    kubectl apply -f https://repo1.dso.mil/boneyard/kyverno/kyverno/-/raw/main/charts/kyverno-crds.yaml
    kubectl apply -f https://repo1.dso.mil/boneyard/kyverno/kyverno/-/raw/main/charts/kyverno-values.yaml || true

    # Using standard Kyverno install
    kubectl create -f https://repo1.dso.mil/dsop/kyverno/kyverno/-/raw/main/install/release-1.7.yaml 2>/dev/null || \
    kubectl apply -f https://raw.githubusercontent.com/kyverno/kyverno/main/config/release/install.yaml || true

    # Install OPA Gatekeeper
    log_info "Installing OPA Gatekeeper..."
    kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml || true

    # Install Falco
    log_info "Installing Falco..."
    helm repo add falcosecurity https://falcosecurity.github.io/charts || true
    helm repo update
    helm install falco falcosecurity/falco --namespace falco --create-namespace -f "$PROJECT_ROOT/monitors/falco/values.yaml" || true

    log_success "Security tools installed"
}

# Deploy monitoring
deploy_monitoring() {
    log_info "Deploying monitoring stack..."

    # Deploy audit policy
    log_info "Deploying audit logging..."
    kubectl apply -f "$PROJECT_ROOT/monitors/audit-logs/audit-policy.yaml"

    # Deploy Falco rules
    log_info "Deploying Falco detection rules..."
    kubectl apply -f "$PROJECT_ROOT/monitors/falco/advanced-rules.yaml"

    # Deploy forensics tools
    log_info "Deploying forensics tools..."
    chmod +x "$PROJECT_ROOT/monitors/forensics/collect-evidence.sh"
    chmod +x "$PROJECT_ROOT/monitors/audit-logs/analyze-audit.sh"

    log_success "Monitoring deployed"
}

# Deploy defenses
deploy_defenses() {
    log_info "Deploying defense systems..."

    # Network policies
    log_info "Deploying network policies..."
    kubectl apply -f "$PROJECT_ROOT/defenses/networkpolicies/"

    # Pod security
    log_info "Deploying pod security..."
    kubectl apply -f "$PROJECT_ROOT/defenses/podsecurity/"

    # RBAC hardening
    log_info "Deploying RBAC policies..."
    kubectl apply -f "$PROJECT_ROOT/defenses/rbac/"

    # Remediation
    log_info "Deploying automated remediation..."
    kubectl apply -f "$PROJECT_ROOT/defenses/remediation/"

    log_success "Defenses deployed"
}

# Deploy policies
deploy_policies() {
    log_info "Deploying admission policies..."

    # Kyverno policies
    if kubectl get crd clusterpolicies.kyverno.io &>/dev/null; then
        log_info "Deploying Kyverno policies..."
        kubectl apply -f "$PROJECT_ROOT/policies/kyverno/"
    else
        log_warning "Kyverno not installed, skipping Kyverno policies"
    fi

    # OPA policies
    if kubectl get crd constrainttemplates.config.gatekeeper.io &>/dev/null; then
        log_info "Deploying OPA policies..."
        kubectl apply -f "$PROJECT_ROOT/policies/opa/"
    else
        log_warning "OPA Gatekeeper not installed, skipping OPA policies"
    fi

    log_success "Policies deployed"
}

# Deploy attack scenarios
deploy_attacks() {
    log_info "Deploying attack scenarios..."

    # Supply chain attacks
    log_info "Deploying supply chain attacks..."
    kubectl apply -f "$PROJECT_ROOT/attacks/supply-chain/"

    # Lateral movement attacks
    log_info "Deploying lateral movement attacks..."
    kubectl apply -f "$PROJECT_ROOT/attacks/lateral-movement/"

    # Persistence attacks
    log_info "Deploying persistence attacks..."
    kubectl apply -f "$PROJECT_ROOT/attacks/persistence/"

    # DoS attacks
    log_info "Deploying DoS attacks..."
    kubectl apply -f "$PROJECT_ROOT/attacks/dos/"

    # Legacy attacks
    log_info "Deploying legacy attacks..."
    kubectl apply -f "$PROJECT_ROOT/attacks/rbac-misuse/" 2>/dev/null || true
    kubectl apply -f "$PROJECT_ROOT/attacks/secrets-exfil/" 2>/dev/null || true

    log_success "Attack scenarios deployed"
}

# Run validation
run_validation() {
    log_info "Running validation..."

    # Validate defenses
    if [ -f "$PROJECT_ROOT/tests/validators/validate-defenses.sh" ]; then
        chmod +x "$PROJECT_ROOT/tests/validators/validate-defenses.sh"
        bash "$PROJECT_ROOT/tests/validators/validate-defenses.sh" || true
    fi

    # Generate dashboard
    if [ -f "$PROJECT_ROOT/dashboard/generate-dashboard.sh" ]; then
        chmod +x "$PROJECT_ROOT/dashboard/generate-dashboard.sh"
        bash "$PROJECT_ROOT/dashboard/generate-dashboard.sh"
    fi

    log_success "Validation complete"
}

# Show status
show_status() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "📊 Lab Status"
    echo "━━��━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    echo ""
    echo "☸️  Cluster:"
    kubectl get nodes -o wide 2>/dev/null || echo "  Cluster not accessible"

    echo ""
    echo "📦 Namespaces:"
    kubectl get namespaces 2>/dev/null | head -10

    echo ""
    echo "🔒 Security Tools:"
    kubectl get pods -n kyverno -o name 2>/dev/null | head -3 || echo "  Kyverno: Not installed"
    kubectl get pods -n falco -o name 2>/dev/null | head -3 || echo "  Falco: Not installed"

    echo ""
    echo "🎯 Attack Scenarios:"
    kubectl get deployments --all-namespaces 2>/dev/null | grep -E "poisoned|flooder|stealer|rootkit|backdoor|interception" | head -10 || echo "  None deployed"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "Setup complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Monitor with: kubectl logs -n falco -l app=falco -f"
    echo "  2. Run tests: ./tests/test-runner.sh"
    echo "  3. Generate dashboard: ./dashboard/generate-dashboard.sh"
    echo ""
}

# Main execution
main() {
    echo "🎯 K8s Attack-Defense Lab - Complete Setup"
    echo "============================================"
    echo ""

    check_prerequisites
    setup_cluster
    install_tools
    deploy_monitoring
    deploy_defenses
    deploy_policies
    deploy_attacks
    run_validation
    show_status
}

# Handle arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Complete setup for K8s Attack-Defense Lab"
        echo ""
        echo "Options:"
        echo "  --help, -h    Show this help"
        echo "  --cluster     Only setup cluster"
        echo "  --tools     Only install tools"
        echo "  --attacks   Only deploy attacks"
        echo "  --defenses Only deploy defenses"
        echo "  --validate Only run validation"
        echo ""
        exit 0
        ;;
    --cluster)
        check_prerequisites
        setup_cluster
        ;;
    --tools)
        check_prerequisites
        install_tools
        ;;
    --attacks)
        deploy_attacks
        ;;
    --defenses)
        deploy_defenses
        ;;
    --validate)
        run_validation
        ;;
    *)
        main
        ;;
esac