variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "region" {
  description = "Region"
  type        = string
}

variable "zone" {
  description = "Zone"
  type        = string
}

variable "network_id" {
  description = "Network ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "service_account_email" {
  description = "Service Account Email"
  type        = string
}

variable "storage_bucket_name" {
  description = "Storage Bucket Name for Dataproc"
  type        = string
}
