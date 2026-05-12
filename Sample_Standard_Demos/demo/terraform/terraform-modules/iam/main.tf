resource "google_service_account" "demo_sa" {
  project      = var.project_id
  account_id   = "demo-service-account"
  display_name = "Demo Service Account"
}

resource "google_project_iam_member" "sa_storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.demo_sa.email}"
}

resource "google_project_iam_member" "user_viewer" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "user:${var.gcp_account_name}"
}

output "service_account_email" {
  value = google_service_account.demo_sa.email
}

output "service_account_name" {
  value = google_service_account.demo_sa.name
}
