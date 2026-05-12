resource "google_cloud_run_v2_service" "demo_run" {
  project  = var.project_id
  name     = "demo-run-service"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "allow_unauth" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.demo_run.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloudfunctions2_function" "demo_function" {
  project     = var.project_id
  name        = "demo-function"
  location    = var.region
  description = "A simple demo function"

  build_config {
    runtime     = "python310"
    entry_point = "hello_http"
    source {
      storage_source {
        bucket = var.storage_bucket_name
        object = google_storage_bucket_object.function_source.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
  }
}

resource "google_storage_bucket_object" "function_source" {
  name   = "sources/function-source.zip"
  bucket = var.storage_bucket_name
  source = "./terraform-modules/scripts/sample-function.zip" # Relative to root execution
}
