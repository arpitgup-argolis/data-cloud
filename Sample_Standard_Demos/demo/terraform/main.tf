################################################################################################
# ROOT MODULE: Sample Standard Demos Orchestration
# 
# USAGE INSTRUCTIONS:
# 1. This file serves as the main entry point for the demo infrastructure.
# 2. To ENABLE a service: Keep the corresponding 'module' block below.
# 3. To DISABLE a service: Simply comment out or remove its 'module' block.
# 4. Customization: Each module's logic is isolated in './terraform-modules/<name>'.
#    Edit the sub-module main.tf for resource-specific changes.
# 5. Variables: Define mandatory values in the root 'variables.tf'.
################################################################################################

# --- CORE INFRASTRUCTURE ---

module "vpc" {
  source       = "./terraform-modules/vpc"
  project_id   = var.project_id
  region       = var.region
  network_name = var.network_name
  subnet_name  = var.subnet_name
  subnet_cidr  = var.subnet_cidr
}

module "iam" {
  source           = "./terraform-modules/iam"
  project_id       = var.project_id
  gcp_account_name = var.gcp_account_name
}

module "gcs" {
  source              = "./terraform-modules/gcs"
  project_id          = var.project_id
  region              = var.region
  storage_bucket_name = var.storage_bucket_name
}

module "bigquery" {
  source        = "./terraform-modules/bigquery"
  project_id    = var.project_id
  region        = var.region
  bq_dataset_id = var.bq_dataset_id
}

module "databases" {
  source     = "./terraform-modules/databases"
  project_id = var.project_id
  region     = var.region
  network_id = module.vpc.network_id
}

module "compute_and_ai" {
  source                = "./terraform-modules/compute_and_ai"
  project_id            = var.project_id
  region                = var.region
  zone                  = var.zone
  network_id            = module.vpc.network_id
  subnet_id             = module.vpc.subnet_id
  service_account_email = module.iam.service_account_email
  storage_bucket_name   = module.gcs.bucket_name
}

module "pubsub" {
  source     = "./terraform-modules/pubsub"
  project_id = var.project_id
}

module "serverless" {
  source              = "./terraform-modules/serverless"
  project_id          = var.project_id
  region              = var.region
  storage_bucket_name = module.gcs.bucket_name
}

module "security" {
  source     = "./terraform-modules/security"
  project_id = var.project_id
  region     = var.region
}

module "orchestration" {
  source               = "./terraform-modules/orchestration"
  project_id           = var.project_id
  region               = var.region
  network_id           = module.vpc.network_id
  subnet_id            = module.vpc.subnet_id
  service_account_name = module.iam.service_account_name
}

module "colab_enterprise" {
  source              = "./terraform-modules/colab_enterprise"
  project_id          = var.project_id
  region              = var.region
  gcp_account_name    = var.gcp_account_name
  colab_template_name = module.compute_and_ai.colab_template_name
}

module "custom_scripts" {
  source              = "./terraform-modules/custom_scripts"
  project_id          = var.project_id
  bq_dataset_id       = module.bigquery.dataset_id
  alloydb_instance_ip = module.databases.alloydb_instance_ip
  storage_bucket_name = module.gcs.bucket_name
  sample_table_id     = module.bigquery.sample_table_id
}
