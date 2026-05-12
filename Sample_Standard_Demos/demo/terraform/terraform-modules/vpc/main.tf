resource "google_compute_network" "main_network" {
  project                 = var.project_id
  name                    = var.network_name
  description             = "Main VPC network for the demo"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "main_subnet" {
  project       = var.project_id
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.main_network.id
}

resource "google_compute_firewall" "allow_internal" {
  project  = var.project_id
  name     = "${var.network_name}-allow-internal"
  network  = google_compute_network.main_network.id
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  source_ranges = [var.subnet_cidr]
}

resource "google_compute_firewall" "allow_iap_tcp_forwarding" {
  project       = var.project_id
  name          = "allow-iap-tcp-forwarding"
  network       = google_compute_network.main_network.id
  source_ranges = ["35.235.240.0/20"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["allow-ssh"]
}

resource "google_compute_router" "router" {
  project = var.project_id
  name    = "${var.network_name}-router"
  region  = var.region
  network = google_compute_network.main_network.id
}

resource "google_compute_router_nat" "nat" {
  project                            = var.project_id
  name                               = "${var.network_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

output "network_id" {
  value = google_compute_network.main_network.id
}

output "subnet_id" {
  value = google_compute_subnetwork.main_subnet.id
}
