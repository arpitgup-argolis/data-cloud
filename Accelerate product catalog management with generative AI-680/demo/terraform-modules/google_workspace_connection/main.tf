terraform {
  #required_version = ">0.7.0"
  required_providers {
    googleworkspace = {
      source  = "hashicorp/googleworkspace"
      version = ">= 0.7.0"
    }
  }
}
data "googleworkspace_group" "data_sharing" {
  email = "allowlist-product-catalog-mgmt@argolis-tools.altostrat.com"
}
output "group_name" {
  value = data.googleworkspace_group.data_sharing.name
}
output "group_id" {
  value = data.googleworkspace_group.data_sharing.id
}
data "googleworkspace_group_members" "data_sharing" {
  group_id = data.googleworkspace_group.data_sharing.id
  include_derived_membership = true
}
output "members" {
  value = data.googleworkspace_group_members.data_sharing.members[*].email
}