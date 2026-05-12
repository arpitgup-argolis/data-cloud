terraform {
  required_version = ">= 0.13"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 3.53"
      configuration_aliases = [google.service_principal_impersonation]
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 3.53"
    }
  }
}
