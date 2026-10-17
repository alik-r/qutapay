locals {
  oncall_permissions = [
    "container.clusters.get", # needed by `gcloud container clusters get-credentials`
    "container.pods.get", "container.pods.list", "container.pods.getLogs",
    "container.deployments.get", "container.deployments.list",
    "logging.logEntries.list", "monitoring.timeSeries.list",
  ]
}

# Day-to-day on-call: read pods, read logs, exec into nothing, read no secrets
resource "google_project_iam_custom_role" "oncall_reader" {
  role_id     = "qutapayOncallReader"
  title       = "Qutapay on-call reader"
  permissions = local.oncall_permissions
}