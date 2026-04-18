#!/bin/bash

# GCP GKE Deployment Script

set -e

# Store original directory
ORIGINAL_DIR=$(pwd)

echo "🌥️ Deploying K8s Attack-Defense Lab to GCP GKE"
echo "=============================================="

# Check prerequisites
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is required. Please install it first."
    exit 1
fi

if ! command -v gcloud &> /dev/null; then
    echo "❌ Google Cloud SDK is required. Please install it first."
    exit 1
fi

# Validate required environment variables
if [ -z "$GCP_PROJECT_ID" ]; then
    echo "❌ GCP_PROJECT_ID environment variable must be set"
    echo "Example: export GCP_PROJECT_ID=my-project-id"
    exit 1
fi

# Authenticate (but don't force login if already authenticated)
echo "🔐 Checking GCP authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "."; then
    echo "⚠️  Not authenticated with GCP. Please run 'gcloud auth login' first."
    echo "Or set service account credentials with 'gcloud auth activate-service-account'"
    exit 1
fi

# Set project
echo "📋 Setting GCP project..."
gcloud config set project "$GCP_PROJECT_ID"
if [ $? -ne 0 ]; then
    echo "❌ Failed to set GCP project"
    exit 1
fi

# Navigate to GCP deployment directory
echo "📂 Changing to GCP deployment directory..."
cd "$ORIGINAL_DIR/cloud-deploy/gcp" || {
    echo "❌ Failed to change to GCP deployment directory"
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
echo "🚀 Deploying to GCP..."
terraform apply tfplan
if [ $? -ne 0 ]; then
    echo "❌ Terraform apply failed"
    cd "$ORIGINAL_DIR" || exit 1
    exit 1
fi

# Get kubectl config
echo "🔧 Configuring kubectl..."
eval $(terraform output -raw kubectl_config)
if [ $? -ne 0 ]; then
    echo "⚠️  Warning: Failed to configure kubectl automatically"
    echo "💡 Try manually running: $(terraform output -raw kubectl_config)"
fi

# Return to original directory
cd "$ORIGINAL_DIR" || {
    echo "❌ Failed to return to original directory"
    exit 1
}

# Deploy lab components (using proper paths)
echo "📦 Deploying lab components..."
if [ -f "cluster/kind-config.yaml" ]; then
    echo "⚠️  Note: Deploying Kind config to GKE (may need adjustments)"
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

echo "✅ GCP GKE deployment complete!"
echo ""
echo "🔗 Access your cluster:"
echo "kubectl get nodes"
echo ""
echo "🧪 Run tests:"
echo "./tests/test-runner.sh"
