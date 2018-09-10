resource "random_string" "grr-db-password" {
  length = 16
  special = false
}

resource "random_string" "grr-admin-user-password" {
  length = 16
  special = false
}

resource "google_compute_firewall" "allow-external-grr-frontend" {
  name    = "allow-external-grr-frontend"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-external-grr-frontend"]
}

resource "google_sql_database_instance" "grr-db-instance" {
  name   = "grr-db-instance-${random_id.infrastructure-random-id.hex}"
  region = "${var.gcp_region}"

  settings {
    tier = "db-n1-standard-1"

    ip_configuration {
      ipv4_enabled = true

      authorized_networks = {
        name  = "grr-server"
        value = "${google_compute_address.grr-server-address.address}"
      }
    }

    location_preference {
      zone = "${var.gcp_region}-b"
    }

    database_flags {
      name  = "max_allowed_packet"
      value = "1073741824"
    }
  }
}

resource "google_sql_user" "grr-db-user" {
  name     = "grr"
  instance = "${google_sql_database_instance.grr-db-instance.name}"
  host     = "${google_compute_address.grr-server-address.address}"
  password = "${random_string.grr-db-password.result}}"
}

resource "google_sql_database" "grr-db" {
  name     = "grr-db"
  instance = "${google_sql_database_instance.grr-db-instance.name}"
}

resource "google_compute_address" "grr-server-address" {
  name = "grr-server-address"
}

resource "google_storage_bucket" "grr-client-installers" {
  name          = "grr-client-installers-${random_id.infrastructure-random-id.hex}"
  force_destroy = true
}

data "template_file" "grr-startup-script" {
  template = "${file("${path.module}/startup_scripts/grr-server.sh")}"

  vars {
    grr_server_host               = "${google_compute_address.grr-server-address.address}"
    grr_db_host                   = "${google_sql_database_instance.grr-db-instance.ip_address.0.ip_address}"
    grr_db_name                   = "${google_sql_database.grr-db.name}"
    grr_db_user                   = "${google_sql_user.grr-db-user.name}"
    grr_db_password               = "${google_sql_user.grr-db-user.password}"
    grr_client_installers_bucket  = "${google_storage_bucket.grr-client-installers.url}"
    grr_admin_user                = "${var.grr_admin_user}"
    grr_admin_password            = "${random_string.grr-admin-user-password.result}"
  }
}

resource "google_compute_instance" "grr-server" {
  depends_on   = ["google_sql_database.grr-db"]

  name         = "grr-server"
  machine_type = "${var.grr_machine_type}"
  zone         = "${var.gcp_zone}"

  tags = ["allow-external-https", "allow-external-grr-frontend"]

  # Use default Ubuntu image as operating system.
  boot_disk {
    initialize_params {
      image = "${var.gcp_ubuntu_1604_image}"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = "${google_compute_address.grr-server-address.address}"
    }
  }

  service_account {
    scopes = ["compute-ro", "storage-rw"]
  }

  # Provision the machine with a script.
  metadata_startup_script = "${data.template_file.grr-startup-script.rendered}"
}

output "GRR server url" {
  value = "https://${google_compute_address.grr-server-address.address}/"
}

output "GRR admin username" {
  value = "${var.grr_admin_user}"
}

output "GRR admin password" {
  value = "${random_string.grr-admin-user-password.result}"
}

output "GRR client installers" {
  value = "${google_storage_bucket.grr-client-installers.url}"
}
