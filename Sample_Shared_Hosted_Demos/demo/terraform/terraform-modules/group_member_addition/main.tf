terraform {
  #required_version = ">= 0.13"
  required_providers {
    googleworkspace = {
      source  = "hashicorp/googleworkspace"
      version = ">= 0.7.0"
    }
  }
}
variable "user_email" {}
variable "group_ID" {}
resource "googleworkspace_group_member" "new_member" {
  group_id = var.group_ID
  email    = var.user_email
  role = "MEMBER"
  timeouts {
    create = "20m"
  }
  lifecycle {
    prevent_destroy = true
  }
}
