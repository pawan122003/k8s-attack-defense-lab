#!/bin/bash

# Azure AKS Deployment Script

set -e

# Store original directory
ORIGINAL_DIR=$(pwd)

echo "🔷 Deploying K8s Attack-Defense Lab to Azure AKS"
echo "================================================"

# Check prerequisites
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is required. Please install it first."
    exit 1
fi

if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is required. Please install it first."
    exit 1
fi

# Validate required environment variables
if [ -z "$AZURE_SUBSCRIPTION_ID" ]; then
    echo "❌ AZURE_SUBSCRIPTION_ID environment variable must be set"
    echo "Example: export AZURE_SUBSCRIPTION_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    exit 1
fi

# Authenticate (but don't force login if already authenticated)
echo "🔐 Checking Azure authentication..."
if ! az account show &> /dev/null; then
    echo "🔐 Authenticating with Azure..."
    az login
    if [ $? -ne 0 ]; then
        echo "❌ Azure authentication failed"
        exit 1
    fi
fi

# Set subscription
echo "📋 Setting Azure subscription..."
az account set --subscription "$AZURE_SUBSCRIPTION_ID"
if [ $? -ne 0 ]; then
    echo "❌ Failed to set Azure subscription"
    exit 1
fi

# Navigate to Azure deployment directory
echo "📂 Changing to Azure deployment directory..."
cd "$ORIGINAL_DIR/cloud-deploy/azure" || {
    echo "❌ Failed to change to Azure deployment directory"
    exit 1
}

# Check if Terraform files exist
if [ ! -f "*.tf" ]; then
    echo "❌ No Terraform files found in current directory"
    cd "$ORIGINAL_DIR" || exit 1
    exit 1
fi

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init
if [ $? -ne 0 ]; then
    echo "❌ Terraform initialization failed"
    cd "$ORIGINAL_DIR" || exit 1
    exit 1
fi

# Plan deployment
echo "📋 Planning deployment..."
terraform plan -out=tfplan
if [ $? -ne 0 ]; then
    echo "❌ Terraform plan failed"
    cd "$ORIGINAL_DIR" || exit 1
    exit 1
fi

# Deploy
echo "🚀 Deploying to Azure..."
terraform apply tfplan
if [ $? -ne 0 ]; then
    echo "❌ Terraform apply failed"
    cd "$ORIGINAL_DIR" || exit 1
    exit 1
fi

# Get kubectl config
echo "🔧 Configuring kubectl..."
eval $(terraform output -raw kube_config)
if [ $? -ne 0 ]; then
    echo "⚠️  Warning: Failed to configure kubectl automatically"
    echo "💡 Try manually running: $(terraform output -raw kube_config)"
fi

# Return to original directory
cd "$ORIGINAL_DIR" || {
    echo "❌ Failed to return to original directory"
    exit 1
}

# Deploy lab components (using proper paths)
echo "📦 Deploying lab components..."
if [ -f "cluster/kind-config.yaml" ]; then
    echo "⚠️  Note: Deploying Kind config to AKS (may need adjustments)"
    kubectl apply -f cluster/kind-config.yaml
else
    echo "ℹ️  Kind config not found, skipping"
fi

if [ -d "defenses" ]; then
    kubectl apply -f defenses/
else
    echo "⚠️  Defenses directory not found, skipping"
fi

if [ -d "monitors" ]; then
    kubectl apply -f monitors/
else
    echo "⚠️  Monitors directory not found, skipping"
fi

echo "✅ Azure AKS deployment complete!"
echo ""
echo "🔗 Access your cluster:"
echo "kubectl get nodes"
echo ""
echo "🧪 Run tests:"
echo "./tests/test-runner.sh"
