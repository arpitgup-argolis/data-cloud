# Dedicated VPC for this environment — fully Terraform-managed.
resource "google_compute_network" "vpc" {
  name                    = "${var.prefix}-vpc"
  auto_create_subnetworks = true
  project                 = var.project_id

  depends_on = [time_sleep.api_propagation]
}

# Proxy-only subnet required for regional internal HTTP(S) LB (gke-l7-rilb)
resource "google_compute_subnetwork" "proxy_only" {
  name          = "${var.prefix}-proxy-only-subnet"
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = "192.168.0.0/23"
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_router" "router" {
  name    = "${var.prefix}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.prefix}-nat"
  project                            = var.project_id
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_global_address" "private_ip_alloc" {
  name          = "${var.prefix}-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
  project       = var.project_id
}

resource "google_service_networking_connection" "default" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}

# --- GKE Cluster ---

resource "google_container_cluster" "primary" {
  name     = "${var.prefix}-cluster"
  location = var.region
  project  = var.project_id
  network  = google_compute_network.vpc.name

  deletion_protection = false

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/14"
    services_ipv4_cidr_block = "/20"
  }

  remove_default_node_pool = true
  initial_node_count       = 1

  node_config {
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  addons_config {
    gcs_fuse_csi_driver_config {
      enabled = true
    }
    parallelstore_csi_driver_config {
      enabled = true
    }
    lustre_csi_driver_config {
      enabled = true
    }
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
      auto_monitoring_config {
        scope = "ALL"
      }
    }
  }

  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }

  depends_on = [
    time_sleep.api_propagation
  ]
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.prefix}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  project    = var.project_id
  node_count = 1

  node_config {
    machine_type = "e2-standard-2"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    shielded_instance_config {
      enable_secure_boot = true
      enable_integrity_monitoring = true
    }
    linux_node_config {
      cgroup_mode = "CGROUP_MODE_V2"
    }
  }
}

resource "google_container_node_pool" "gpu_nodes" {
  name     = "${var.prefix}-gpu-pool"
  location = var.region
  cluster  = google_container_cluster.primary.name
  project  = var.project_id

  # Autoscaling configuration
  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  node_locations = var.node_locations

  node_config {
    # L4 GPU machine type
    machine_type = var.gpu_machine_type

    guest_accelerator {
      type  = var.gpu_accelerator_type
      count = 1
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    shielded_instance_config {
      enable_secure_boot = true
      enable_integrity_monitoring = true
    }

    linux_node_config {
      cgroup_mode = "CGROUP_MODE_V2"
    }

    # Taints to ensure only GPU workloads run here
    taint {
      key    = "nvidia.com/gpu"
      value  = "present"
      effect = "NO_SCHEDULE"
    }

    labels = {
      "accelerator" = var.gpu_accelerator_type
    }
  }
}

# --- GCS & Service Accounts ---

resource "google_storage_bucket" "models" {
  name                        = "${var.prefix}-models-${var.project_id}" # Ensure global uniqueness
  location                    = var.region
  project                     = var.project_id
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_service_account" "model_reader" {
  account_id   = "${var.prefix}-model-reader"
  display_name = "Model Reader Service Account for ${var.prefix}"
  project      = var.project_id

  depends_on = [time_sleep.api_propagation]
}

resource "google_service_account" "agent_sa" {
  account_id   = "${var.prefix}-agent-sa"
  display_name = "Agent Service Account for ${var.prefix}"
  project      = var.project_id

  depends_on = [time_sleep.api_propagation]
}

resource "google_project_iam_member" "agent_vertex_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.agent_sa.email}"
}

resource "google_project_iam_member" "agent_cloud_assist" {
  project = var.project_id
  role    = "roles/geminicloudassist.user"
  member  = "serviceAccount:${google_service_account.agent_sa.email}"
}

resource "google_storage_bucket_iam_member" "reader" {
  bucket = google_storage_bucket.models.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.model_reader.email}"
}

resource "google_storage_bucket_iam_member" "writer" {
  # Grant writer access initially to allow uploads, or restrict if using a separate admin SA.
  # For simplicity in this setup, we'll allow the same SA to write (e.g. for the transfer job).
  bucket = google_storage_bucket.models.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.model_reader.email}"
}

resource "google_project_iam_member" "trace_agent" {
  project = var.project_id
  role    = "roles/cloudtrace.agent"
  member  = "serviceAccount:${google_service_account.model_reader.email}"
}

resource "google_project_iam_member" "vertex_ai_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.model_reader.email}"
}

# Granting the Storage Object Viewer role to the Compute Engine Service Account for Build execution.
data "google_project" "project" {
  project_id = var.project_id
}
# Define the specific roles required for the Compute Engine Service Account
locals {
  compute_sa_roles = [
    "roles/storage.objectViewer",
    "roles/logging.logWriter",
    "roles/artifactregistry.repoAdmin",
  ]
}
# Grant specific roles to the Compute Engine Service Account
resource "google_project_iam_member" "compute_sa_iam" {
  for_each = toset(local.compute_sa_roles)

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}
# Grant Cloud Build Editor role to the Demo user
resource "google_project_iam_member" "user_cloudbuild_editor" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "user:${var.gcp_account_email}"
}

# --- Model Sync from Shared Bucket ---

resource "null_resource" "model_sync" {
  triggers = {
    # Trigger if the destination bucket changes
    destination_bucket = google_storage_bucket.models.url
  }

  provisioner "local-exec" {
    command = <<EOF
      echo "🚀 Syncing models from central bucket..."
      SRC_BUCKET="gs://${var.model_location}/gemma-4-e4b-it-weights"
      
      echo "Copying from $SRC_BUCKET to ${google_storage_bucket.models.url}..."
      gcloud storage rsync -r "$SRC_BUCKET" "${google_storage_bucket.models.url}/"
    EOF
  }

  depends_on = [google_storage_bucket.models]
}