/**
* Copyright 2024 Google LLC
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

# Add your Terraform configuration here for Patient Handoff demo

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project               = var.project_id
  region                = var.region
  user_project_override = true
  billing_project       = var.project_id
}

# Get project number - we'll handle this more gracefully
data "google_project" "project" {
  count      = var.skip_project_lookup ? 0 : 1
  project_id = var.project_id
}

# Secret Manager for tmo credentials
data "google_secret_manager_secret_version" "get_credentials_for_TMO_authentication" {
  project = var.secret_stored_project
  secret = "argolis-tmo-sa-delegation"
}

provider "google" {
  alias       = "SharedHostedProject_DomainWideDelegation" # Give it an alias
  credentials = data.google_secret_manager_secret_version.get_credentials_for_TMO_authentication.secret_data
}

locals {
  # If we can't get the project number, construct it from the project ID
  # The user can override this with var.project_number if needed
  project_number = var.project_number != "" ? var.project_number : (
    var.skip_project_lookup ? "" : (
      length(data.google_project.project) > 0 ? data.google_project.project[0].number : ""
    )
  )
  
  # Use the default Cloud Build service account
  cloudbuild_sa = local.project_number != "" ? "${local.project_number}@cloudbuild.gserviceaccount.com" : ""
  # Alternative compute service account that might be used
  compute_sa = local.project_number != "" ? "${local.project_number}-compute@developer.gserviceaccount.com" : ""
  
  # Use gcp_account_name as initial_user if initial_user is not provided
  effective_initial_user = var.initial_user != "" ? var.initial_user : var.gcp_account_name
  
  # Deployment service account (if provided)
  deployment_sa = var.deployment_service_account_name != "" ? var.deployment_service_account_name : ""
  
  # GCS bucket name for app data (if enabled)
  gcs_bucket_name = var.gcs_bucket_name != "" ? var.gcs_bucket_name : "patient-handoff-data-${var.project_id}-${var.region}"
}

# Note: Cloud Run service is deployed by Cloud Build, not Terraform
# The Cloud Build pipeline (ctd_cloudbuild.yaml) handles:
# - Cloning the GitLab repository
# - Building the Docker image
# - Pushing to Artifact Registry
# - Deploying to Cloud Run with the built image

# Enable required APIs - conditionally based on variable
resource "google_project_service" "required_apis" {
  for_each = var.enable_apis ? toset([
    "compute.googleapis.com",
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "iap.googleapis.com",
    "aiplatform.googleapis.com",
    "generativelanguage.googleapis.com",
    "apikeys.googleapis.com",
    "storage.googleapis.com",
    "certificatemanager.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "containerscanning.googleapis.com",
  ]) : toset([])
  
  project = var.project_id
  service = each.value
  
  disable_on_destroy = false
}

# Keep legacy API resources for backward compatibility
resource "google_project_service" "run_api" {
  count   = var.enable_apis ? 0 : 1
  project = var.project_id
  service = "run.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "compute_api" {
  count   = var.enable_apis ? 0 : 1
  project = var.project_id
  service = "compute.googleapis.com"

  disable_on_destroy = false
}

# Wait for APIs to be enabled
resource "time_sleep" "wait_for_apis" {
  count = var.enable_apis ? 1 : 0
  depends_on = [google_project_service.required_apis]
  
  create_duration = "60s"
}

# Create API key for Gemini using google-beta provider
resource "google_apikeys_key" "gemini_api_key" {
  provider     = google-beta
  name         = "gemini-api-key"
  display_name = "Gemini API Key for Patient Handoff"
  project      = var.project_id

  restrictions {
    api_targets {
      service = "generativelanguage.googleapis.com"
    }
    api_targets {
      service = "aiplatform.googleapis.com"
    }
  }

  depends_on = [google_project_service.required_apis]
}

# Create Secret Manager secret for GitLab token
resource "google_secret_manager_secret" "gitlab_token" {
  secret_id = "gitlab-token"
  project   = var.project_id
  
  replication {
    auto {}
  }
  
  depends_on = [google_project_service.required_apis]
}

# Data source to access the secret version from the hosted project
data "google_secret_manager_secret_version_access" "gitlab_token_source" {
  provider = google.SharedHostedProject_DomainWideDelegation
  project = var.hosted_project_id  #  the ID of the project hosting the source secret
  secret  = "Click-To-Deploy-Accessible-Gitlab-Token"  # secret ID in the HOSTED project
}

# Create secret version with the GitLab token
resource "google_secret_manager_secret_version" "gitlab_token_version" {
  secret      = google_secret_manager_secret.gitlab_token.id
  secret_data = data.google_secret_manager_secret_version_access.gitlab_token_source.secret_data
}

# Create Secret Manager secret for Gemini API key
resource "google_secret_manager_secret" "gemini_api_key" {
  secret_id = "gemini-api-key"
  project   = var.project_id
  
  replication {
    auto {}
  }
  
  depends_on = [google_project_service.required_apis]
}

# Store Gemini API key in Secret Manager
resource "google_secret_manager_secret_version" "gemini_api_key_version" {
  secret      = google_secret_manager_secret.gemini_api_key.id
  secret_data = google_apikeys_key.gemini_api_key.key_string
}

# Grant Cloud Build service account access to the GitLab token secret
resource "google_secret_manager_secret_iam_member" "cloudbuild_secret_access" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.gitlab_token.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.cloudbuild_sa}"
  
  depends_on = [
    time_sleep.wait_for_apis,
    google_secret_manager_secret_version.gitlab_token_version
  ]
}

# Grant Cloud Build service account access to the Gemini API key secret
resource "google_secret_manager_secret_iam_member" "cloudbuild_gemini_secret_access" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.gemini_api_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.cloudbuild_sa}"
  
  depends_on = [
    time_sleep.wait_for_apis,
    google_secret_manager_secret_version.gemini_api_key_version
  ]
}

# Also grant Compute Engine default service account access to the GitLab token secret
resource "google_secret_manager_secret_iam_member" "compute_secret_access" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.gitlab_token.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.compute_sa}"
  
  depends_on = [
    time_sleep.wait_for_apis,
    google_secret_manager_secret_version.gitlab_token_version
  ]
}

# Grant Compute Engine default service account access to the Gemini API key secret
resource "google_secret_manager_secret_iam_member" "compute_gemini_secret_access" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.gemini_api_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.compute_sa}"
  
  depends_on = [
    time_sleep.wait_for_apis,
    google_secret_manager_secret_version.gemini_api_key_version
  ]
}

# Create Artifact Registry repository
resource "google_artifact_registry_repository" "patient_handoff" {
  repository_id = "patient-handoff"
  description   = "Patient Handoff Docker images"
  format        = "DOCKER"
  location      = var.region
  project       = var.project_id
  
  depends_on = [google_project_service.required_apis]
}

# Create Terraform state bucket with random suffix to avoid conflicts
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "google_storage_bucket" "terraform_state" {
  name          = "${var.project_id}-tfstate-${random_id.bucket_suffix.hex}"
  location      = var.region
  project       = var.project_id
  force_destroy = true
  
  versioning {
    enabled = true
  }
  
  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }
  
  depends_on = [google_project_service.required_apis]
}

# Grant Cloud Build service account necessary IAM roles
resource "google_project_iam_member" "cloudbuild_permissions" {
  for_each = toset([
    "roles/run.admin",
    "roles/artifactregistry.admin",
    "roles/storage.admin",
    "roles/cloudbuild.builds.builder",
    "roles/secretmanager.secretAccessor",
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountAdmin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/compute.admin",
    "roles/certificatemanager.editor",
    "roles/iap.admin",
    "roles/logging.logWriter",
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${local.cloudbuild_sa}"
  
  depends_on = [time_sleep.wait_for_apis]
}

# Grant Compute Engine default service account the same IAM roles as Cloud Build
resource "google_project_iam_member" "compute_permissions" {
  for_each = toset([
    "roles/run.admin",
    "roles/artifactregistry.admin",
    "roles/storage.admin",
    "roles/cloudbuild.builds.builder",
    "roles/secretmanager.secretAccessor",
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountAdmin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/compute.admin",
    "roles/certificatemanager.editor",
    "roles/iap.admin",
    "roles/logging.logWriter",
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${local.compute_sa}"
  
  depends_on = [time_sleep.wait_for_apis]
}

# Grant Cloud Build service account access to the state bucket
resource "google_storage_bucket_iam_member" "state_bucket_access" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${local.cloudbuild_sa}"
  
  depends_on = [time_sleep.wait_for_apis]
}

# Grant deployment service account access if provided
resource "google_project_iam_member" "deployment_sa_permissions" {
  for_each = local.deployment_sa != "" && local.deployment_sa != local.cloudbuild_sa ? toset([
    "roles/run.admin",
    "roles/artifactregistry.admin",
    "roles/storage.admin",
    "roles/cloudbuild.builds.builder",
    "roles/secretmanager.secretAccessor",
    "roles/iam.serviceAccountUser",
  ]) : toset([])
  
  project = var.project_id
  role    = each.value
  member  = local.deployment_sa
  
  depends_on = [time_sleep.wait_for_apis]
}

# Grant deployment service account access to the state bucket if provided
resource "google_storage_bucket_iam_member" "deployment_sa_state_bucket_access" {
  count  = local.deployment_sa != "" && local.deployment_sa != local.cloudbuild_sa ? 1 : 0
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.objectAdmin"
  member = local.deployment_sa
}

# Wait for IAM permissions to propagate
resource "time_sleep" "wait_for_iam" {
  depends_on = [
    google_project_iam_member.cloudbuild_permissions,
    google_project_iam_member.deployment_sa_permissions,
    google_storage_bucket_iam_member.state_bucket_access,
    google_storage_bucket_iam_member.deployment_sa_state_bucket_access,
    google_secret_manager_secret_iam_member.cloudbuild_secret_access,
    google_secret_manager_secret_iam_member.compute_secret_access,
  ]
  
  create_duration = "60s"
}

# Automatically deploy the application when creating resources (if auto_deploy is true)
resource "null_resource" "deploy_application" {
  count = var.auto_deploy ? 1 : 0
  
  triggers = {
    always_run = timestamp()
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "======================================"
      echo "Deploying Patient Handoff application..."
      echo "======================================"
      echo ""
      echo "Submitting Cloud Build job..."
      gcloud builds submit \
        --config=cloudbuild/ctd_cloudbuild.yaml \
        --no-source \
        --substitutions=_REGION=${var.region},_INITIAL_USER=${local.effective_initial_user} \
        --project=${var.project_id}
      echo ""
      echo "======================================"
      echo "Deployment submitted. Check the Cloud Console for progress:"
      echo "https://console.cloud.google.com/cloud-build/builds?project=${var.project_id}"
      echo "======================================"
    EOT
    working_dir = "${path.module}"
  }
  
  depends_on = [
    google_project_iam_member.cloudbuild_permissions,
    google_artifact_registry_repository.patient_handoff,
    google_storage_bucket.terraform_state,
    google_storage_bucket_iam_member.state_bucket_access,
    google_secret_manager_secret_version.gitlab_token_version,
    time_sleep.wait_for_iam,
  ]
}

# Show deployment instructions if auto_deploy is false
resource "null_resource" "manual_deploy_instructions" {
  count = var.auto_deploy ? 0 : 1
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "======================================"
      echo "Cloud Build infrastructure is ready!"
      echo "======================================"
      echo ""
      echo "Auto-deploy is disabled. To deploy the application manually, run:"
      echo ""
      echo "gcloud builds submit \\"
      echo "  --config=cloudbuild/ctd_cloudbuild.yaml \\"
      echo "  --no-source \\"
      echo "  --substitutions=_REGION=${var.region},_INITIAL_USER=${local.effective_initial_user} \\"
      echo "  --project=${var.project_id}"
      echo ""
      echo "======================================"
    EOT
    working_dir = "${path.module}"
  }
  
  depends_on = [
    google_project_iam_member.cloudbuild_permissions,
    google_artifact_registry_repository.patient_handoff,
    google_storage_bucket.terraform_state,
  ]
}

# Store values for destroy provisioner
resource "null_resource" "destroy_app_resources" {
  triggers = {
    project_id = var.project_id
    region     = var.region
  }
  
  # Provisioner to run destroy build when this resource is destroyed
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "======================================"
      echo "Destroying Patient Handoff application resources..."
      echo "======================================"
      gcloud builds submit \
        --config=cloudbuild/ctd_cloudbuild_destroy.yaml \
        --no-source \
        --substitutions=_REGION=${self.triggers.region} \
        --project=${self.triggers.project_id} || true
      echo "Waiting for destroy to complete..."
      sleep 30
    EOT
    working_dir = "${path.module}"
    on_failure  = continue
  }
  
  depends_on = [
    google_project_iam_member.cloudbuild_permissions,
    google_storage_bucket.terraform_state,
  ]
}

# Create GCS bucket (optional)
resource "google_storage_bucket" "app_bucket" {
  count = var.create_gcs_bucket ? 1 : 0

  name     = local.gcs_bucket_name
  location = var.gcs_bucket_location
  project  = var.project_id

  uniform_bucket_level_access = true

  # Lifecycle rules (optional)
  dynamic "lifecycle_rule" {
    for_each = var.gcs_lifecycle_rules
    content {
      action {
        type = lifecycle_rule.value.action_type
      }
      condition {
        age = lifecycle_rule.value.age
      }
    }
  }
}

# Grant Cloud Run service account access to GCS bucket
# Only create IAM binding if we're also creating the bucket
resource "google_storage_bucket_iam_member" "bucket_access" {
  count = var.enable_gcs_mount && var.grant_bucket_access && var.create_gcs_bucket ? 1 : 0

  bucket = local.gcs_bucket_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.service_account_email != null ? var.service_account_email : local.compute_sa}"

  depends_on = [
    google_storage_bucket.app_bucket,
    google_project_service.required_apis,
    google_project_service.run_api
  ]
}
