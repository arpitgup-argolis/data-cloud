resource "google_compute_instance" "demo_vm" {
  project      = var.project_id
  name         = "demo-instance"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["allow-ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = var.network_id
    subnetwork = var.subnet_id
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }
}

resource "google_workbench_instance" "demo_notebook" {
  project  = var.project_id
  name     = "demo-notebook"
  location = var.zone

  gce_setup {
    machine_type = "n1-standard-4"
    network_interfaces {
      network    = var.network_id
      subnetwork = var.subnet_id
    }
    service_accounts {
      email = var.service_account_email
    }
  }
}

resource "google_ai_platform_dataset" "demo_dataset" {
  project             = var.project_id
  display_name        = "demo_dataset"
  region              = var.region
  metadata_schema_uri = "gs://google-cloud-aiplatform/schema/dataset/metadata/tabular_1.0.0.yaml"
}

resource "google_dataproc_cluster" "demo_cluster" {
  project = var.project_id
  name    = "demo-dataproc-cluster"
  region  = var.region

  cluster_config {
    staging_bucket = var.storage_bucket_name

    master_config {
      num_instances = 1
      machine_type  = "n1-standard-4"
      disk_config {
        boot_disk_size_gb = 30
      }
    }

    worker_config {
      num_instances = 2
      machine_type  = "n1-standard-4"
      disk_config {
        boot_disk_size_gb = 30
      }
    }

    gce_cluster_config {
      subnetwork = var.subnet_id
      service_account = var.service_account_email
      service_account_scopes = ["cloud-platform"]
    }
  }
}

resource "google_colab_runtime_template" "demo_template" {
  project      = var.project_id
  name         = "demo-colab-template"
  display_name = "Demo Colab Template"
  location     = var.region

  machine_spec {
    machine_type = "n1-standard-4"
  }

  network_spec {
    enable_internet_access = true
    network                = var.network_id
    subnetwork             = var.subnet_id
  }
}

output "colab_template_name" {
  value = google_colab_runtime_template.demo_template.name
}
