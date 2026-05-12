resource "google_sql_database_instance" "demo_sql" {
  project          = var.project_id
  name             = "demo-sql-instance"
  database_version = "MYSQL_8_0"
  region           = var.region
  deletion_protection = false

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled = true
    }
  }
}

resource "google_sql_database" "demo_db" {
  name     = "demo-database"
  instance = google_sql_database_instance.demo_sql.name
}

resource "google_spanner_instance" "demo_spanner" {
  project          = var.project_id
  config           = "regional-${var.region}"
  display_name     = "Demo Spanner Instance"
  processing_units = 100
}

resource "google_spanner_database" "demo_spanner_db" {
  instance = google_spanner_instance.demo_spanner.name
  name     = "demo-db"
  deletion_protection = false
}

resource "google_alloydb_cluster" "demo_alloydb" {
  project    = var.project_id
  cluster_id = "demo-alloydb-cluster"
  location   = var.region
  
  network_config {
    network = var.network_id
  }

  initial_user {
    password = "alloydb-password"
  }
}

resource "google_alloydb_instance" "demo_alloydb_instance" {
  cluster       = google_alloydb_cluster.demo_alloydb.name
  instance_id   = "demo-alloydb-instance"
  instance_type = "PRIMARY"

  machine_config {
    cpu_count = 2
  }
}

resource "google_firestore_database" "demo_datastore" {
  project     = var.project_id
  name        = "(default)"
  location_id = var.region
  type        = "DATASTORE_MODE"
  delete_protection_state = "DELETE_PROTECTION_DISABLED"
}

output "alloydb_instance_ip" {
  value = google_alloydb_instance.demo_alloydb_instance.ip_address
}
