resource "google_bigquery_dataset" "main_dataset" {
  project                     = var.project_id
  dataset_id                  = var.bq_dataset_id
  friendly_name               = "Demo Dataset"
  description                 = "Dataset for demo resources"
  location                    = var.region
  delete_contents_on_destroy  = true

  labels = {
    env = "demo"
  }
}

resource "google_bigquery_table" "sample_table" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.main_dataset.dataset_id
  table_id   = "sample_data"
  
  deletion_protection = false

  time_partitioning {
    type = "DAY"
  }

  labels = {
    env = "demo"
  }

  schema = <<EOF
[
  {
    "name": "id",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Unique ID"
  },
  {
    "name": "timestamp",
    "type": "TIMESTAMP",
    "mode": "NULLABLE",
    "description": "Event timestamp"
  },
  {
    "name": "value",
    "type": "FLOAT64",
    "mode": "NULLABLE",
    "description": "Event value"
  }
]
EOF
}

resource "google_bigquery_table" "sample_view" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.main_dataset.dataset_id
  table_id            = "sample_view"
  deletion_protection = false
  
  view {
    query          = "SELECT * FROM `${var.project_id}.${google_bigquery_dataset.main_dataset.dataset_id}.${google_bigquery_table.sample_table.table_id}`"
    use_legacy_sql = false
  }
}

output "dataset_id" {
  value = google_bigquery_dataset.main_dataset.dataset_id
}

output "sample_table_id" {
  value = google_bigquery_table.sample_table.table_id
}
