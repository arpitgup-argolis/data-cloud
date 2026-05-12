resource "google_artifact_registry_repository" "demo_repo" {
  project       = var.project_id
  location      = var.region
  repository_id = "demo-repo"
  description   = "Docker repository for demo images"
  format        = "DOCKER"
}

resource "google_secret_manager_secret" "demo_secret" {
  project   = var.project_id
  secret_id = "demo-api-key"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "demo_secret_v1" {
  secret      = google_secret_manager_secret.demo_secret.id
  secret_data = "super-secret-value"
}

resource "google_kms_key_ring" "demo_keyring" {
  project  = var.project_id
  name     = "demo-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "demo_key" {
  name            = "demo-key"
  key_ring        = google_kms_key_ring.demo_keyring.id
  rotation_period = "7776000s"

  lifecycle {
    prevent_destroy = false
  }
}
