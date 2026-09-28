terraform {
  required_version = ">= 1.6"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 6.0" }
  }

  backend "gcs" {
    prefix = "00-bootstrap"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region

  user_project_override = true
  billing_project       = var.project_id
}

# APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com", "container.googleapis.com", "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com", "pubsub.googleapis.com",
    "secretmanager.googleapis.com", "artifactregistry.googleapis.com",
    "iam.googleapis.com", "iamcredentials.googleapis.com", "sts.googleapis.com",
    "cloudresourcemanager.googleapis.com", "monitoring.googleapis.com",
    "logging.googleapis.com", "billingbudgets.googleapis.com",
  ])
  service            = each.value
  disable_on_destroy = false
}

# Terraform state
resource "google_storage_bucket" "tfstate" {
  name                        = "${var.project_id}-tfstate"
  location                    = var.region
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
  lifecycle {
    prevent_destroy = true
  }
}

# Container images
resource "google_artifact_registry_repository" "images" {
  repository_id = "qutapay"
  location      = var.region
  format        = "DOCKER"
  cleanup_policies {
    id     = "untagged"
    action = "DELETE"
    condition {
      tag_state  = "UNTAGGED"
      older_than = "604800s"
    }
  }

  depends_on = [google_project_service.apis]
}

# Cost guard
resource "google_billing_budget" "guard" {
  billing_account = var.billing_account
  display_name    = "qutapay-monthly"
  budget_filter {
    projects = ["projects/${var.project_number}"]
  }
  amount {
    specified_amount {
      currency_code = "USD"
      units         = "50"
    }
  }
  dynamic "threshold_rules" {
    for_each = [0.5, 0.9, 1.0]
    content {
      threshold_percent = threshold_rules.value
    }
  }

  depends_on = [google_project_service.apis]
}
