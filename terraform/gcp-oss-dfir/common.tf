resource "random_id" "infrastructure-random-id" {
  byte_length = 8
}

# Allow SSH from external to instances with tag allow-external-ssh
resource "google_compute_firewall" "allow-external-ssh" {
  name    = "allow-external-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-external-ssh"]
}

# Allow plaintext HTTP from external to instances with tag allow-external-http
resource "google_compute_firewall" "allow-external-http" {
  name    = "allow-external-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-external-http"]
}

# Allow HTTPS from external to instances with tag allow-external-https
resource "google_compute_firewall" "allow-external-https" {
  name    = "allow-external-https"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-external-https"]
}
