# -------------------------------------------------------------------
# Hypercomputer – Unified Click-To-Deploy Module
# -------------------------------------------------------------------

terraform {
  required_version = ">= 1.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

/*
# -------------------------------------------------------------------
# Baseline
# -------------------------------------------------------------------

module "baseline_policies" {
  source     = "../../org_policy"
  project_id = var.project_id
}
*/

locals {
  effective_image_url = var.image_url != "" ? var.image_url : "asia-southeast1-docker.pkg.dev/${var.project_id}/chatbot-repo/chatbot:latest"
  effective_cloud_run_image_url = var.cloud_run_image_url != "" ? var.cloud_run_image_url : "asia-southeast1-docker.pkg.dev/${var.project_id}/chatbot-repo/chatbot:latest"
}

# -------------------------------------------------------------------
# Kubernetes Dynamic Provider
# -------------------------------------------------------------------

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.infra.cluster_endpoint}"
  cluster_ca_certificate = base64decode(module.infra.cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

provider "kubectl" {
  host                   = "https://${module.infra.cluster_endpoint}"
  cluster_ca_certificate = base64decode(module.infra.cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
  load_config_file       = false
}

# -------------------------------------------------------------------
# Module: infra (VPC, GKE, GCS, Service Accounts)
# -------------------------------------------------------------------
module "infra" {
  # depends_on           = [module.baseline_policies]
  source               = "../terraform-modules/infra"
  project_id           = var.project_id
  region               = var.region
  prefix               = var.env_prefix
  gpu_machine_type     = var.gpu_machine_type
  gpu_accelerator_type = var.gpu_accelerator_type
  node_locations       = var.node_locations
  gcp_account_email    = var.gcp_account_name
  model_location       = var.data_location
}

resource "time_sleep" "wait_for_infra" {
  create_duration = "80s"

  depends_on = [
    module.infra
  ]
}

# -------------------------------------------------------------------
# Prerequisite: Build Custom Chatbot Image
# -------------------------------------------------------------------
resource "null_resource" "ensure_artifact_registry" {
  depends_on = [time_sleep.wait_for_infra]

  provisioner "local-exec" {
    command = <<EOF
      gcloud artifacts repositories create chatbot-repo \
        --repository-format=docker \
        --location=asia-southeast1 \
        --description="Chatbot Docker repository" \
        --project=${var.project_id} --quiet || echo "Repository exists."
EOF
  }
}

resource "null_resource" "build_chatbot_image" {
  depends_on = [null_resource.ensure_artifact_registry]

  provisioner "local-exec" {
    command = <<EOF
      cd ../../demo/src
      gcloud builds submit --config cloudbuild.yaml \
        --substitutions=_LOCATION="asia-southeast1",_REPOSITORY_ID="chatbot-repo",_IMAGE_NAME="chatbot",_IMAGE_TAG="latest" \
        --project=${var.project_id} --quiet
EOF
  }
}

# -------------------------------------------------------------------
# Module: cloud_run (Cloud Run Service for Chatbot)
# -------------------------------------------------------------------
module "cloud_run" {
  depends_on   = [null_resource.build_chatbot_image, time_sleep.wait_for_infra]
  count        = var.cloud_run_active ? 1 : 0
  source       = "../terraform-modules/cloud_run"

  project_id   = var.project_id
  region       = var.region
  env_prefix   = var.env_prefix
  image_url    = local.effective_cloud_run_image_url
  service_name = var.cloud_run_service_name
  port         = var.cloud_run_port
  use_gemini_api = var.use_gemini_api
  agent_sa_email = module.infra.agent_sa_email
}

# -------------------------------------------------------------------
# Module: app (K8s Deployments & Gemma Model Download)
# -------------------------------------------------------------------
module "app" {
  depends_on   = [time_sleep.wait_for_infra]
  count                 = var.app_active ? 1 : 0
  source                = "../terraform-modules/app"

  project_id            = var.project_id
  cluster_name          = module.infra.cluster_name
  prefix                = var.env_prefix
  image_url             = local.effective_image_url
  app_version           = var.app_version
  model_name            = var.model_name
  vllm_image            = var.vllm_image
  gpu_type              = module.infra.gpu_type
  model_bucket_name     = module.infra.model_bucket_name
  model_reader_sa_email = module.infra.model_reader_sa_email
  agent_sa_email        = module.infra.agent_sa_email

  use_gemini_api           = var.use_gemini_api
  gemini_model_name        = var.gemini_model_name
  region                   = var.region
  enable_vllm              = var.enable_vllm
  enable_inference_gateway = var.enable_inference_gateway
  hpa_target_cpu           = var.vllm_hpa_target_cpu

  model_subdir             = var.model_subdir
  model_served_name        = var.model_served_name
  model_hf_repo            = var.model_hf_repo
  vllm_extra_args          = var.vllm_extra_args
  enable_otel              = var.enable_otel
  model_sync_id            = module.infra.model_sync_id
}

# -------------------------------------------------------------------
# Module: monitoring (Cloud Monitoring Dashboard)
# -------------------------------------------------------------------
module "monitoring" {
  depends_on   = [time_sleep.wait_for_infra]
  count         = var.monitoring_active ? 1 : 0
  source        = "../terraform-modules/monitoring"

  project_id    = var.project_id
  cluster_name  = module.infra.cluster_name
  env_prefix    = var.env_prefix
  create_alerts = var.create_alerts
}