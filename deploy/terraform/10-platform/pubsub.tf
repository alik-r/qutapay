resource "google_pubsub_topic" "payment_succeeded" {
  for_each = module.services.envs
  name     = "payment-succeeded-${each.value}"
}

resource "google_pubsub_subscription" "payment_succeeded_dispatch" {
  for_each = module.services.envs
  name     = "payment-succeeded-dispatch-${each.value}"
  topic    = google_pubsub_topic.payment_succeeded[each.value].id

  ack_deadline_seconds    = 10
  enable_message_ordering = true
}