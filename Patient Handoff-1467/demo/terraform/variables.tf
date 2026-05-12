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
  description = "Email address of the user performing the demo"
}
variable "deployment_service_account_name" {
  type        = string
  description = "Cloud Build service account having permission to deploy terraform resources (optional)"
  default     = ""
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

# Project and Region
variable "region" {
  description = "The GCP region for the Cloud Run service"
  type        = string
  default     = "us-west1"
}

# Service Configuration
variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string
  default     = "patient-handoff"
}

variable "ingress" {
  description = "Ingress settings for the service"
  type        = string
  default     = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  validation {
    condition     = contains(["INGRESS_TRAFFIC_ALL", "INGRESS_TRAFFIC_INTERNAL_ONLY", "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"], var.ingress)
    error_message = "Ingress must be one of: INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  }
}

# Container Configuration
variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "applet-proxy-1"
}

variable "container_image" {
  description = "Container image URL (will be built and pushed by Cloud Build)"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "base_image_uri" {
  description = "Base image URI for the container. If set, enables automatic base image updates. Example: us-central1-docker.pkg.dev/serverless-runtimes/google-22/runtimes/nodejs22"
  type        = string
  default     = null
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "port_name" {
  description = "Port protocol name (http1 or h2c)"
  type        = string
  default     = "http1"
  validation {
    condition     = contains(["http1", "h2c"], var.port_name)
    error_message = "Port name must be either 'http1' or 'h2c'"
  }
}

# Environment Variables
variable "environment_variables" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "secret_environment_variables" {
  description = "Environment variables from Secret Manager"
  type = map(object({
    secret  = string
    version = string
  }))
  default = {}
}

# Resource Limits
variable "cpu_limit" {
  description = "CPU limit for the container (e.g., '1', '2', '4')"
  type        = string
  default     = "1"
  validation {
    condition     = contains(["1", "2", "4", "6", "8"], var.cpu_limit)
    error_message = "CPU limit must be one of: 1, 2, 4, 6, 8"
  }
}

variable "memory_limit" {
  description = "Memory limit for the container (e.g., '512Mi', '1Gi', '2Gi')"
  type        = string
  default     = "512Mi"
}

variable "cpu_idle" {
  description = "Whether CPU is only allocated during requests"
  type        = bool
  default     = true
}

variable "startup_cpu_boost" {
  description = "Whether to boost CPU on startup"
  type        = bool
  default     = false
}

# Scaling Configuration
variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 3
}

variable "max_concurrency" {
  description = "Maximum number of concurrent requests per instance"
  type        = number
  default     = 80
}

variable "timeout_seconds" {
  description = "Request timeout in seconds"
  type        = number
  default     = 300
}

# Execution Environment
variable "execution_environment" {
  description = "Execution environment generation"
  type        = string
  default     = "EXECUTION_ENVIRONMENT_GEN2"
  validation {
    condition     = contains(["EXECUTION_ENVIRONMENT_GEN1", "EXECUTION_ENVIRONMENT_GEN2"], var.execution_environment)
    error_message = "Execution environment must be GEN1 or GEN2"
  }
}

variable "session_affinity" {
  description = "Enable session affinity"
  type        = bool
  default     = false
}

# VPC Configuration
variable "vpc_connector" {
  description = "VPC connector name (optional)"
  type        = string
  default     = null
}

variable "vpc_egress" {
  description = "VPC egress setting"
  type        = string
  default     = "PRIVATE_RANGES_ONLY"
  validation {
    condition     = contains(["ALL_TRAFFIC", "PRIVATE_RANGES_ONLY"], var.vpc_egress)
    error_message = "VPC egress must be ALL_TRAFFIC or PRIVATE_RANGES_ONLY"
  }
}

# Service Account
variable "service_account_email" {
  description = "Service account email (uses default compute SA if not specified)"
  type        = string
  default     = null
}

# GCS Volume Mount
variable "enable_gcs_mount" {
  description = "Enable GCS bucket mount"
  type        = bool
  default     = true
}

variable "gcs_bucket_name" {
  description = "GCS bucket name for volume mount. If empty, will auto-generate as patient-handoff-data-{project-id}-{region}"
  type        = string
  default     = ""
}

variable "gcs_mount_path" {
  description = "Container path where GCS bucket will be mounted"
  type        = string
  default     = "/app/dist"
}

variable "gcs_read_only" {
  description = "Mount GCS bucket as read-only"
  type        = bool
  default     = true
}

variable "gcs_mount_options" {
  description = "List of flags to pass to gcsfuse for configuring the GCS volume mount. Flags should be passed without leading dashes. Example: ['only-dir=services/patient-handoff/version-24/compiled']"
  type        = list(string)
  default     = []
}

variable "create_gcs_bucket" {
  description = "Whether to create the GCS bucket"
  type        = bool
  default     = true
}

variable "gcs_bucket_location" {
  description = "Location for the GCS bucket"
  type        = string
  default     = "US"
}

variable "grant_bucket_access" {
  description = "Grant service account access to GCS bucket"
  type        = bool
  default     = true
}

variable "gcs_lifecycle_rules" {
  description = "Lifecycle rules for GCS bucket"
  type = list(object({
    action_type = string
    age         = number
  }))
  default = []
}

# Health Probes
variable "enable_startup_probe" {
  description = "Enable startup probe"
  type        = bool
  default     = true
}

variable "startup_probe_timeout" {
  description = "Startup probe timeout in seconds"
  type        = number
  default     = 240
}

variable "startup_probe_period" {
  description = "Startup probe period in seconds"
  type        = number
  default     = 240
}

variable "startup_probe_failure_threshold" {
  description = "Startup probe failure threshold"
  type        = number
  default     = 1
}

variable "enable_liveness_probe" {
  description = "Enable liveness probe"
  type        = bool
  default     = false
}

variable "liveness_probe_timeout" {
  description = "Liveness probe timeout in seconds"
  type        = number
  default     = 1
}

variable "liveness_probe_period" {
  description = "Liveness probe period in seconds"
  type        = number
  default     = 10
}

variable "liveness_probe_failure_threshold" {
  description = "Liveness probe failure threshold"
  type        = number
  default     = 3
}

variable "liveness_probe_path" {
  description = "HTTP path for liveness probe"
  type        = string
  default     = "/"
}

# Secret Volumes
variable "secret_volumes" {
  description = "Secret volumes to mount"
  type = map(object({
    secret       = string
    default_mode = number
    items = list(object({
      path    = string
      version = string
      mode    = number
    }))
  }))
  default = {}
}

# Traffic Configuration
variable "traffic_splits" {
  description = "Traffic split configuration"
  type = list(object({
    type     = string
    percent  = number
    revision = optional(string)
    tag      = optional(string)
  }))
  default = [
    {
      type     = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
      percent  = 100
      revision = null
      tag      = null
    }
  ]
}

# IAM Configuration
variable "allow_unauthenticated" {
  description = "Allow unauthenticated access to the service"
  type        = bool
  default     = false
}

variable "iap_enabled" {
  description = "Enable Identity-Aware Proxy (IAP) for the service. Requires launch_stage = BETA"
  type        = bool
  default     = false
}

variable "invoker_iam_disabled" {
  description = "Disable IAM permission check for run.routes.invoke for callers of this service. When true, the service URL will not perform any IAM check when invoked."
  type        = bool
  default     = false
}

# Click-to-Deploy Configuration
variable "initial_user" {
  description = "Email address of the initial user to grant IAP access (defaults to gcp_account_name if not specified)"
  type        = string
  default     = ""
}

variable "gitlab_token" {
  description = "GitLab access token for cloning repository (OPTIONAL - hardcoded for this release)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "auto_deploy" {
  description = "Whether to automatically deploy the application when running terraform apply"
  type        = bool
  default     = true
}

variable "enable_apis" {
  description = "Whether to enable Google Cloud APIs (set to false if APIs are already enabled)"
  type        = bool
  default     = true
}

variable "skip_project_lookup" {
  description = "Skip looking up project details (useful if you don't have project viewer permissions)"
  type        = bool
  default     = false
}

# Declaring hosted project id to access the Gitlab token via secret manager using dWD
variable "hosted_project_id" {
  type        = string
  description = "hosted project id to access gitlab secret"
  default     = "patient-handoff-1467" 
}

