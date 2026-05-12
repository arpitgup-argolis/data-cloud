####################################################################################
# Add User to the Group for the Shared project
####################################################################################
terraform {
  required_providers {
     google = {
      source  = "hashicorp/google"
      version = ">= 6.0.0"
    }
  }
}
/*
locals {
  prefix_account = trimprefix("${var.gcp_account_name}", "admin@")
  suffix_account = trimsuffix("${local.prefix_account}", ".altostrat.com")
  google_account = format("%s@google.com", "${local.suffix_account}")
}
*/
# Secret Manager
data "google_secret_manager_secret_version" "test_secret" {
  project = var.secret_stored_project
  secret = "argolis-golden-demos-data-groups-management"
  version = "1"
}

provider "googleworkspace" {
  alias = "Domain-wide-delegation"
  customer_id  = "C03exzez5"
  impersonated_user_email = "api-user@argolis-tools.altostrat.com"
  oauth_scopes = ["https://www.googleapis.com/auth/admin.directory.group"]
  credentials  = data.google_secret_manager_secret_version.test_secret.secret_data
}
module "group_connection" {
    providers = { googleworkspace = googleworkspace.Domain-wide-delegation }
    source = "../terraform-modules/google_workspace_connection"
}
module "member_addition" {
    count = contains(module.group_connection.members, var.gcp_account_name) ? 0 : 1
    providers = { googleworkspace = googleworkspace.Domain-wide-delegation }
    source = "../terraform-modules/group_member_addition"
    user_email = var.gcp_account_name
    group_ID = module.group_connection.group_id
}
/*
module "member_addition_2" {
    count = contains(module.group_connection.members, "${local.google_account}") ? 0 : 1
    providers = { googleworkspace = googleworkspace.Domain-wide-delegation }
    source = "../terraform-modules/group_member_addition"
    user_email = "${local.google_account}"
    group_ID = module.group_connection.group_id
}
*/
resource "null_resource" "delete_project" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOF
gcloud projects delete ${var.project_id} --billing-project=${var.project_id}
EOF
  }
  depends_on = [
    module.member_addition,
    module.group_connection
  ]
}

output "email" {
  value = module.group_connection.members
}