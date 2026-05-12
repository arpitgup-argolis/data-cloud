provider "google" {
  project = var.project_id
}
provider "google" {
  alias                 = "service_principal_impersonation"
  project               = var.project_id
  region                = var.location
  user_project_override = true
  impersonate_service_account = "${var.Service_Account_name}-${random_id.server.hex}@${var.project_id}.iam.gserviceaccount.com"
}
provider "aws" {
  alias      = "IAM"
  region     = var.aws_location
  access_key = local.local_access_key
  secret_key = local.local_secret_key
}

resource "random_id" "server" {
  byte_length = 4
}
locals {
  local_access_key  = data.google_secret_manager_secret_version.AWS_ACCESSS_KEY.secret_data
  local_secret_key  = data.google_secret_manager_secret_version.AWS_SECRET_KEY.secret_data
}
data "google_secret_manager_secret_version" "AWS_ACCESSS_KEY" {
  project = var.TMO_Project
  secret = "REDSHIFT_DEMO_AWS_ACCESS_KEY"
}
data "google_secret_manager_secret_version" "AWS_SECRET_KEY" {
  project = var.TMO_Project
  secret = "REDSHIFT_DEMO_SECRET_ACCESS_KEY"
}

#get details of users present in the aws group
module "User_availibility_check" {
  providers = { aws = aws.IAM}
  source                = "./IAM_USER_Check"
  aws_group_name        = var.aws_group_name
}
#If user is not present then create user and its profile and save it in Secret Manager
module "create_user" {
  count = contains(module.User_availibility_check.user_in_aws, "s3gcs-${var.gcp_account_name}") ? 0 : 1
  providers = { aws = aws.IAM}
  source                = "./IAM_USER_Creation"
  CE_User               = "s3gcs-${var.gcp_account_name}"
  project_id            = var.project_id
  depends_on            = [module.User_availibility_check]
}
#If user is already present then create credentials again and save it in Secret Manager
module "create_user_profile" {
  count = contains(module.User_availibility_check.user_in_aws, "s3gcs-${var.gcp_account_name}") ? 1 : 0
  providers = { aws = aws.IAM}
  source                = "./IAM_USER_Profile_Creation"
  CE_User               = "s3gcs-${var.gcp_account_name}"
  project_id            = var.project_id
  Access_Key            = local.local_access_key
  Secret_Key            = local.local_secret_key
  depends_on            = [module.User_availibility_check]
}
module "User_Additon_AWS_Group" {
  count = contains(module.User_availibility_check.users_in_aws_group, "s3gcs-${var.gcp_account_name}") ? 0 : 1
  providers = { aws = aws.IAM}
  source                = "./IAM_USER_Addition"
  aws_group_name        = var.aws_group_name
  member_name           = "s3gcs-${var.gcp_account_name}"
  depends_on            = [module.create_user]
}

# Create the aws-discovery-sa to run the discovery job 

resource "google_service_account" "aws-discovery-sa" {
  project = var.project_id
  account_id   = "aws-discovery-sa"
  display_name = "AWS Discovery service Account"
  description  = "Managed by Terraform - used to run discovery job"
}

# Assign roles to the above Service Account

resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.aws-discovery-sa.email}"
}

resource "google_project_iam_member" "migration_admin" {
  project = var.project_id
  role    = "roles/migrationcenter.admin"
  member  = "serviceAccount:${google_service_account.aws-discovery-sa.email}"
}
