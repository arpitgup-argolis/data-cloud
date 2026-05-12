########################################################################
# MANDATORY: Variables which are required in each Click-To-Deploy Demos#
# There values are being passed from build cloudbuild.yaml file        #
# during terraform apply.                                              #
########################################################################
variable "project_id" {
  type        = string
  description = "project id required"
}

variable "project_name" {
  type        = string
  description = "project name in which demo deploy"
}

variable "project_number" {
  type        = string
  description = "project number in which demo deploy"
}

variable "gcp_account_name" {
  type        = string
  description = "user performing the demo"
}

variable "deployment_service_account_name" {
  type        = string
  description = "Cloudbuild_Service_account having permission to deploy terraform resources"
}

variable "org_id" {
  type        = string
  description = "Organization ID in which project created"
}

variable "data_location" {
  type        = string
  description = "Location of source data file in central bucket"
}

variable "secret_stored_project" {
  type        = string
  description = "Project where secret is accessing from"
}