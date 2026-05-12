#below variables are predefined variables
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
 description = "user performing the demo"
}
variable "deployment_service_account_name" {
 description = "Cloudbuild_Service_account having permission to deploy terraform resources"
}
variable "org_id" {
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
variable "TMO_Project" {
  type        = string
  default     = "dw-migration-redshift"
}

#below variables have hardcoded values
variable "Service_Account_name" {
  type        = string
  default     = "redshift-bq"
}
variable "dataset_id_prod" {
  type        = string
  default     = "dwmr_prod"
}
variable "dataset_id_dev" {
  type        = string
  default     = "dwmr_dev"
}
variable "Prod_Schema" {
  type        = string
  default     = "dwmr_prod"
}
variable "Dev_Schema" {
  type        = string
  default     = "dwmr_dev"
}
variable "aws_location" {
  type =  string
  default = "us-east-1"
  }
variable "location" {
  type        = string
  default     = "us-east4"
}
variable "DTS_Name_Prod" {
  type        = string
  default     = "Redshift_to_BigQuery_Prod"
}
variable "DTS_Name_Dev" {
  type        = string
  default     = "Redshift_to_BigQuery_Dev"
}
variable "data_source_id" {
  type        = string
  default     = "redshift"
}
variable "database_user" {
  type        = string
  default     = "awsuser"
}
variable "s3_staging_bucket" {
  type        = string
  default     = "s3://data-warehouse-modernization-redshift-bucket/dts_staging"
}
variable "aws_group_name" {
  type        = string
  default     = "grp-vmmig-user-1529"
}
variable "AWS_Bucket" {
  type        = string
  default     = "data-warehouse-modernization-redshift-bucket"
}


#For Module dwmh_Validation Automation
variable "database_name_prod" {
  type        = string
  default     = "prod"
}
variable "database_name_dev" {
  type        = string
  default     = "dev"
}
variable "BQ_Connection_Name" {
  type        = string
  default     = "BQ_CONN_CTD"
}
variable "REDSHIFT_Connection_Name" {
  type        = string
  default     = "REDSHIFT_CONN_CTD"
}

#For Module CE_Validation_Tool Manual
variable "vpc_name" {
  type        = string
  default     = "dwhm-data-validation-vpc"
}
variable "firewall_name" {
  type        = string
  default     = "dwhm-data-validation-rule"
}
variable "instance_name" {
  type        = string
  default     = "dwmh-data-validation-vm"
}


#For Module Redshift_Cluster_Details
variable "cluster_identifier" {
  type        = string
  default     = "dwmr-demo-cluster"
}
variable "db_dvt_user" {
  type        = string
  default     = "dvt_user"
}
