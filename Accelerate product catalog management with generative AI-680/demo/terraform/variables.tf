variable "project_id" {
  type        = string
  description = "project id required"
}
variable "gcp_account_name" {
 description = "user performing the demo"
}
variable "secret_stored_project" {
  type        = string
  description = "Project where secret is accessing from"
}
variable "project_name" {
 type        = string
 description = "project name in which demo deploy"
}
variable "project_number" {
 type        = string
 description = "project number in which demo deploy"
}
variable "deployment_service_account_name" {
 description = "Cloudbuild_Service_account having permission to deploy terraform resource"
}
variable "data_location" {
 type        = string
 description = "Location of source data file in central bucket"
}
variable "org_id" {
 description = "Organization ID in which project created"
}