data "google_composer_image_versions" "latest_images" {
  project = var.project_id
  region  = var.region
}

locals {
  composer_2_images = reverse(sort([
    for version in data.google_composer_image_versions.latest_images.image_versions : version.image_version_id
    if startswith(version.image_version_id, "composer-2")
  ]))
}

resource "google_composer_environment" "demo_composer" {
  project = var.project_id
  name    = "demo-composer-env"
  region  = var.region

  config {
    software_config {
      image_version = local.composer_2_images[0]
      pypi_packages = {
        pandas = ">=1.5.0"
      }
      env_variables = {
        PROJECT_ID = var.project_id
      }
    }

    workloads_config {
      scheduler {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        count      = 1
      }
      web_server {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
      }
      worker {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        min_count  = 1
        max_count  = 3
      }
    }

    environment_size = "ENVIRONMENT_SIZE_SMALL"

    node_config {
      network         = var.network_id
      subnetwork      = var.subnet_id
      service_account = var.service_account_name
    }
  }

  timeouts {
    create = "90m"
    update = "90m"
    delete = "90m"
  }
}
