################################################################################################
#  ⚠️  DO NOT MODIFY THIS FILE. IT IS DATA-DRIVEN FROM project_config.json
#      ONLY EDIT project_config.json TO CUSTOMIZE POLICIES OR ENABLE APIS.
################################################################################################

variable "project_id" {
  description = "Project ID where the policies will be applied"
  type        = string
}

locals {
  config      = jsondecode(file("${path.module}/project_config.json"))
  constraints = { for c in local.config.constraints : c.constraint => c }
}

# 1. Enable Required APIs dynamically
resource "google_project_service" "enabled_apis" {
  for_each                   = toset(local.config.apis_to_enable)
  project                    = var.project_id
  service                    = each.key
  disable_dependent_services = true
}

# 2. Apply Organization Policies dynamically
resource "google_org_policy_policy" "dynamic_policies" {
  for_each = local.constraints
  name     = "projects/${var.project_id}/policies/${each.key}"
  parent   = "projects/${var.project_id}"

  spec {
    rules {
      # Handle Boolean Policies
      dynamic "enforce" {
        for_each = each.value.policy_type == "boolean" ? [1] : []
        content {
          value = each.value.enforced ? "TRUE" : "FALSE"
        }
      }

      # Handle List Policies
      dynamic "values" {
        for_each = each.value.policy_type == "list" ? [1] : []
        content {
          allowed_values = each.value.allow_all ? null : each.value.allowed_values
          denied_values  = each.value.deny_all ? null : each.value.denied_values
        }
      }

      # Handle "Allow All" or "Deny All" for List Policies
      dynamic "allow_all" {
        for_each = each.value.policy_type == "list" && each.value.allow_all ? ["TRUE"] : []
        content {
          values = [allow_all.value]
        }
      }
      dynamic "deny_all" {
        for_each = each.value.policy_type == "list" && each.value.deny_all ? ["TRUE"] : []
        content {
          values = [deny_all.value]
        }
      }
    }
  }
}
