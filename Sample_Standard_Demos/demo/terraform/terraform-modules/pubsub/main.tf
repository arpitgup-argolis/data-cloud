resource "google_pubsub_topic" "demo_topic" {
  project = var.project_id
  name    = "demo-topic"
  labels = {
    env = "demo"
  }
}

resource "google_pubsub_subscription" "demo_subscription" {
  project = var.project_id
  name    = "demo-subscription"
  topic   = google_pubsub_topic.demo_topic.name

  message_retention_duration = "604800s"
  retain_acked_messages      = true
  ack_deadline_seconds       = 20

  expiration_policy {
    ttl = "300000.5s"
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  enable_message_ordering = false
}

output "topic_name" {
  value = google_pubsub_topic.demo_topic.name
}
