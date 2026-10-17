data "google_service_account" "svc" {
  for_each   = module.services.identities
  account_id = "qp-${each.key}"
}

# Workload Identity
resource "google_service_account_iam_member" "wi" {
  for_each           = module.services.identities
  service_account_id = data.google_service_account.svc[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[qutapay-${each.value.env}/${each.value.ksa}]"

  depends_on = [google_container_cluster.main]
}

# Pub/sub
resource "google_pubsub_topic_iam_member" "publish" {
  for_each = module.services.publish_grants
  topic    = each.value.topic
  role     = "roles/pubsub.publisher"
  member   = data.google_service_account.svc[each.value.identity].member

  depends_on = [google_pubsub_topic.payment_succeeded]
}

resource "google_pubsub_subscription_iam_member" "subscribe" {
  for_each     = module.services.subscribe_grants
  subscription = each.value.sub
  role         = "roles/pubsub.subscriber"
  member       = data.google_service_account.svc[each.value.identity].member

  depends_on = [google_pubsub_subscription.payment_succeeded_dispatch]
}

# Cloud SQL
resource "google_project_iam_member" "sql_client" {
  for_each = module.services.db_identities
  project  = var.project_id
  role     = "roles/cloudsql.client"
  member   = data.google_service_account.svc[each.key].member
}

resource "google_project_iam_member" "sql_instance_user" {
  for_each = module.services.db_identities
  project  = var.project_id
  role     = "roles/cloudsql.instanceUser"
  member   = data.google_service_account.svc[each.key].member
}

resource "google_sql_user" "iam" {
  for_each        = module.services.db_identities
  instance        = google_sql_database_instance.pg.name
  name            = trimsuffix(data.google_service_account.svc[each.key].email, ".gserviceaccount.com")
  type            = "CLOUD_IAM_SERVICE_ACCOUNT"
  deletion_policy = "ABANDON"
}

resource "google_sql_database" "env" {
  for_each        = module.services.envs
  name            = "qutapay_${each.value}"
  instance        = google_sql_database_instance.pg.name
  deletion_policy = "ABANDON"
}