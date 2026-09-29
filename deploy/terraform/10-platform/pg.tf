resource "random_id" "pg_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "pg" {
  name             = "qutapay-pg-${random_id.pg_suffix.hex}"
  database_version = "POSTGRES_16"
  region           = var.region
  settings {
    edition = "ENTERPRISE"
    tier    = "db-g1-small"
    ip_configuration {
      ipv4_enabled    = false # private only
      private_network = google_compute_network.vpc.id
    }
    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }
    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
    }
  }
  deletion_protection = false

  depends_on = [google_service_networking_connection.psa]
}