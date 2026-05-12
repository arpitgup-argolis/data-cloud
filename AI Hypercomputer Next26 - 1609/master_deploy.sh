#!/bin/bash
# -------------------------------------------------------------------
# master_deploy.sh – Complete Automated Click-to-Deploy Pipeline
# -------------------------------------------------------------------
set -euo pipefail

PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null)}"
if [ -z "$PROJECT_ID" ]; then
  echo "Error: Project ID must be provided as the first argument or set in gcloud config." >&2
  exit 1
fi
LOCATION="asia-southeast1"
REPO_ID="chatbot-repo"
IMAGE_NAME="chatbot"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================================"
echo "🚀 Starting Master Deployment to: ${PROJECT_ID}"
echo "========================================================"

# 1. Target Project
echo "🎯 Setting active gcloud project..."
gcloud config set project "${PROJECT_ID}" --quiet

# 2. Baseline Project (APIs & Policies)
echo "📋 Applying Baseline Project Policies and APIs..."
cd "${SCRIPT_DIR}/org_policy"
terraform init
terraform apply -var="project_id=${PROJECT_ID}" -auto-approve

# 3. Create Artifact Repository (Graceful if exists)
echo "📦 Ensuring Artifact Registry Repository exists..."
gcloud artifacts repositories create "${REPO_ID}" \
    --repository-format=docker \
    --location="${LOCATION}" \
    --description="Chatbot Docker repository" \
    --quiet || echo "Repository already exists, proceeding."

# 4. Build and Push Image
echo "🛠️ Building and pushing custom Chatbot image via Cloud Build..."
cd "${SCRIPT_DIR}/demo/src"
gcloud builds submit --config cloudbuild.yaml \
    --substitutions=_LOCATION="${LOCATION}",_REPOSITORY_ID="${REPO_ID}",_IMAGE_NAME="${IMAGE_NAME}",_IMAGE_TAG="latest" \
    --quiet

# 5. Provision Base Infrastructure (Step 1)
echo "🏗️ Provisioning base infrastructure (VPC, GKE, Cloud Run)..."
cd "${SCRIPT_DIR}/demo/terraform"
./deploy.sh demo step1 apply -auto-approve

# 6. Download Model (Step 2)
echo "⬇️ Initiating Gemma Model download inside GKE..."
./deploy.sh demo step2 apply -auto-approve

echo "========================================================"
echo "🎉 Master Deployment Completed Successfully!"
echo "========================================================"
