################################################################################################
# SHARED HOSTED DEMO: User Onboarding
# 
# This configuration adds a user to a shared Google Workspace group for demo access.
# Note: It deletes the temporary project created during the onboarding process.
################################################################################################

terraform {
  required_version = ">= 1.0.0" # Modernized version constraint
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0" # Modernized provider version
    }
  }
}

# 1. Fetch group management credentials from Secret Manager
data "google_secret_manager_secret_version" "test_secret" {
  project = var.secret_stored_project
  secret  = "argolis-golden-demos-data-groups-management"
}

# 2. Configure Google Workspace provider via impersonation
provider "googleworkspace" {
  customer_id             = "C03exzez5"
  impersonated_user_email = "api-user@argolis-tools.altostrat.com"
  oauth_scopes            = ["https://www.googleapis.com/auth/admin.directory.group"]
  credentials             = data.google_secret_manager_secret_version.test_secret.secret_data
}

# 3. Add user to the shared demo group
module "group_connection" {
    source = "./terraform-modules/google_workspace_connection"
}

module "member_addition" {
    count      = contains(module.group_connection.members, var.gcp_account_name) ? 0 : 1
    source     = "./terraform-modules/group_member_addition"
    user_email = var.gcp_account_name
    group_ID   = module.group_connection.group_id
}

# 4. Cleanup: Delete the temporary project
# This project is created by the Click-To-Deploy backend but is not needed for hosted demos.
resource "null_resource" "delete_project" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "gcloud projects delete ${var.project_id} --billing-project=${var.project_id} --quiet"
  }
  depends_on = [
    module.member_addition,
    module.group_connection
  ]
}
