#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "K8s Attack-Defense Lab - Tool Installation"
echo "============================================"
echo ""

# Essential tools
echo -e "${BLUE}Checking essential tools...${NC}"

ESSENTIAL_TOOLS=(kubectl kind helm)
for tool in "${ESSENTIAL_TOOLS[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✔${NC} $tool - $(command -v $tool)"
    else
        echo -e "  ${RED}✖${NC} $tool - NOT FOUND"
    fi
done

echo ""
echo -e "${BLUE}Checking security tools...${NC}"

# Security tools
SECURITY_TOOLS=(kyverno kubescape kube-bench falco)
for tool in "${SECURITY_TOOLS[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✔${NC} $tool"
    elif kubectl get pods -n "$tool" 2>/dev/null | grep -q Running; then
        echo -e "  ${GREEN}✔${NC} $tool (in cluster)"
    else
        echo -e "  ${YELLOW}⚠${NC} $tool - not installed"
    fi
done

echo ""
echo -e "${BLUE}Checking additional tools...${NC}"

# Additional tools
ADDITIONAL_TOOLS=(flux argocd prometheus grafana trivy grype)
for tool in "${ADDITIONAL_TOOLS[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✔${NC} $tool"
    elif helm list -A 2>/dev/null | grep -q "$tool"; then
        echo -e "  ${GREEN}✔${NC} $tool (helm release)"
    else
        echo -e "  ${YELLOW}⚠${NC} $tool - not installed"
    fi
done

echo ""
echo "============================================"
echo "Installation Instructions:"
echo "============================================"
echo ""
echo "Essential:"
echo "  kubectl    - https://kubernetes.io/docs/tasks/tools/install-kubectl/"
echo "  kind      - https://kind.sigs.k8s.io/docs/user/quick-start/"
echo "  helm     - https://helm.sh/docs/intro/install/"
echo ""
echo "Security:"
echo "  kyverno   - https://kyverno.io/docs/installation/"
echo "  kubescape - https://github.com/kubescape/kubescape"
echo "  kube-bench - https://github.com/aquasecurity/kube-bench"
echo "  falco     - https://falco.org/docs/installation/"
echo ""
echo "Policy Testing:"
echo "  opa       - https://www.openpolicyagent.org/docs/latest/"
echo "  conftest - https://www.conftest.dev/install/"
echo ""
echo "Vulnerability Scanning:"
echo "  trivy     - https://aquasecurity.github.io/trivy/"
echo "  grype    - https://github.com/anchore/grype"
echo ""

exit 0