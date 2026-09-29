resource "google_pubsub_topic" "payment_succeeded" {
    name = "payment-succeeded"
}

resource "google_pubsub_subscription" "payment_succeeded_dispatch" {
    name = "payment-succeeded-dispatch"
    topic = google_pubsub_topic.payment_succeeded.id

    ack_deadline_seconds = 10
    enable_message_ordering = true
}