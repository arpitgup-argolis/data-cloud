resource "google_storage_bucket" "main_bucket" {
  project                     = var.project_id
  name                        = var.storage_bucket_name
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "sample_script" {
  name   = "scripts/hello_world.py"
  bucket = google_storage_bucket.main_bucket.name
  content = "print('Hello World from GCS!')"
}

output "bucket_name" {
  value = google_storage_bucket.main_bucket.name
}
