data "google_client_config" "current" {}

resource "null_resource" "trigger_bq_init" {
  provisioner "local-exec" {
    when    = create
    command = <<EOF
curl -X POST \
  https://bigquery.googleapis.com/bigquery/v2/projects/${var.project_id}/jobs \
  --header "Authorization: Bearer ${data.google_client_config.current.access_token}" \
  --header "Content-Type: application/json" \
  --data '{ "configuration" : { "query" : { "query" : "CALL `${var.project_id}.${var.bq_dataset_id}.initialize`();", "useLegacySql" : false } } }'
EOF
  }
}

resource "null_resource" "gcloud_config" {
  provisioner "local-exec" {
    command = "gcloud config set project ${var.project_id}"
  }
}

resource "null_resource" "bq_load_data" {
  provisioner "local-exec" {
    command = "bq load --source_format=CSV ${var.project_id}:${var.bq_dataset_id}.${var.sample_table_id} gs://${var.storage_bucket_name}/data/sample.csv"
  }
}

resource "null_resource" "alloydb_sql_init" {
  provisioner "local-exec" {
    command = "psql -h ${var.alloydb_instance_ip} -U postgres -d demo-db -f ./terraform-modules/scripts/init_db.sql"
    environment = {
      PGPASSWORD = "alloydb-password"
    }
  }
}
