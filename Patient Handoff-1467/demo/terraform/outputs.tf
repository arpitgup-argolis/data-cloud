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

# Project Outputs
output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region"
  value       = var.region
}

# Infrastructure Outputs
output "artifact_registry_repository" {
  description = "The Artifact Registry repository URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.patient_handoff.repository_id}"
}

output "terraform_state_bucket" {
  description = "The GCS bucket for Terraform state"
  value       = google_storage_bucket.terraform_state.name
}

# GCS Bucket Outputs
output "gcs_bucket_name" {
  description = "Name of the GCS bucket for app data"
  value       = local.gcs_bucket_name
}

output "gcs_bucket_url" {
  description = "URL of the GCS bucket (if created)"
  value       = var.create_gcs_bucket ? "gs://${local.gcs_bucket_name}" : "Not created (create_gcs_bucket = false)"
}

# Service Account Outputs
output "cloudbuild_service_account" {
  description = "The Cloud Build service account email"
  value       = local.cloudbuild_sa
}

output "project_number" {
  description = "The GCP project number"
  value       = local.project_number
}

output "secret_name" {
  description = "The full secret resource name"
  value       = google_secret_manager_secret.gitlab_token.id
}

# Deployment Instructions
output "deploy_command" {
  description = "Command to deploy the application using Cloud Build"
  value       = <<-EOT
    gcloud builds submit \
      --config=cloudbuild/ctd_cloudbuild.yaml \
      --ignore-file=.gcloudignore \
      --substitutions=_REGION=${var.region},_INITIAL_USER=${local.effective_initial_user} \
      --project=${var.project_id}
  EOT
}

output "destroy_command" {
  description = "Command to destroy the application resources"
  value       = <<-EOT
    gcloud builds submit \
      --config=cloudbuild/ctd_cloudbuild_destroy.yaml \
      --ignore-file=.gcloudignore \
      --substitutions=_REGION=${var.region} \
      --project=${var.project_id}
  EOT
}

output "get_service_url_command" {
  description = "Command to get the Cloud Run service URL after deployment"
  value       = "gcloud run services describe ${var.service_name} --region=${var.region} --format='value(status.url)' --project=${var.project_id}"
}

output "next_steps" {
  description = "Next steps after applying Terraform"
  value       = <<-EOT
    Next steps:
    1. ${var.auto_deploy ? "Application deployment has been triggered automatically!" : "Deploy the application:"}
       ${var.auto_deploy ? "Check progress at: https://console.cloud.google.com/cloud-build/builds?project=${var.project_id}" : "gcloud builds submit --config=cloudbuild/ctd_cloudbuild.yaml --ignore-file=.gcloudignore --substitutions=_REGION=${var.region},_INITIAL_USER=${local.effective_initial_user} --project=${var.project_id}"}
    
    2. Wait for the build to complete (check progress in Cloud Console)
    
    3. To get the Cloud Run service URL after deployment:
       gcloud run services describe ${var.service_name} --region=${var.region} --format="value(status.url)" --project=${var.project_id}
    
    4. Access the application at the Cloud Run URL
    
    5. To clean up everything (including app resources):
       terraform destroy
       (This will automatically run cloudbuild/ctd_cloudbuild_destroy.yaml before removing Terraform resources)
  EOT
}
