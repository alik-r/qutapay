resource "google_service_account" "svc" {
  for_each     = module.services.identities
  account_id   = "qp-${each.key}"
  display_name = "${each.value.ksa} (${each.value.env})"

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "s" {
  for_each  = module.services.secret_names
  secret_id = each.value
  replication {
    auto {}
  }
  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_iam_member" "read" {
  for_each  = module.services.secret_grants
  secret_id = google_secret_manager_secret.s[each.value.secret].id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.svc[each.value.identity].member
}