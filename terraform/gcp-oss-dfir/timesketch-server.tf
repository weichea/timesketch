data "template_file" "timesketch-startup-script" {
  template = "${file("${path.module}/startup_scripts/timesketch-server.sh")}"
  vars {
    elasticsearch_node        = "${google_compute_instance.elasticsearch.*.name[0]}"
    timesketch_admin_user     = "${var.timesketch_admin_user}"
    timesketch_admin_password = "${random_string.timesketch-admin-user-password.result}"
  }
}

data "template_file" "elasticsearch-startup-script" {
  template = "${file("${path.module}/startup_scripts/elasticsearch.sh")}"

  vars {
    cluster_name  = "${var.elasticsearch_cluster_name}"
    project       = "${var.gcp_project}"
    zone          = "${var.gcp_zone}"
  }

}

resource "google_compute_address" "timesketch-server-address" {
  name = "timesketch-server-address"
}

resource "random_string" "timesketch-admin-user-password" {
  length = 16
  special = false
}

resource "google_compute_instance" "timesketch" {
  name          = "timesketch-server"
  machine_type  = "${var.timesketch_machine_type}"
  zone          = "${var.gcp_zone}"
  depends_on    = ["google_compute_instance.elasticsearch"]

  # Allow to stop/start the machine to enable change machine type.
  allow_stopping_for_update = true

  # Use default Ubuntu image as operating system.
  boot_disk {
    initialize_params {
      image = "${var.gcp_ubuntu_1604_image}"
      size  = "${var.timesketch_disk_size_gb}"
    }
  }

  # Assign a generated public IP address. Needed for SSH access.
  network_interface {
    network       = "default"

    access_config {
      nat_ip = "${google_compute_address.timesketch-server-address.address}"
    }
  }

  # Allow HTTP(S) traffic
  tags = ["allow-external-http", "allow-external-https"]

  # Provision the machine with a script.
  metadata_startup_script = "${data.template_file.timesketch-startup-script.rendered}"
}

resource "google_compute_instance" "elasticsearch" {
  count        = "${var.elasticsearch_node_count}"
  name         = "elasticsearch-node-${count.index}"
  machine_type = "${var.elasticsearch_machine_type}"
  zone         = "${var.gcp_zone}"

  # Allow to stop/start the machine to enable change machine type.
  allow_stopping_for_update = true

  # Use default Ubuntu image as operating system.
  boot_disk {
    initialize_params {
      image = "${var.gcp_ubuntu_1604_image}"
      size  = "${var.elasticsearch_disk_size_gb}"
    }
  }

  # Assign a generated public IP address. Needed for SSH access.
  network_interface {
    network       = "default"
    access_config = {}
  }

  # Tag for service enumeration.
  tags = ["elasticsearch"]

  # Enable the GCE discovery module to call required APIs.
  service_account {
    scopes = ["compute-ro"]
  }

  # Provision the machine with a script.
  metadata_startup_script = "${data.template_file.elasticsearch-startup-script.rendered}"
}

output "Timesketch server url" {
  value = "https://${google_compute_address.timesketch-server-address.address}/"
}

output "Timesketch admin user" {
  value = "${var.timesketch_admin_user}"
}

output "Timesketch admin password" {
  value = "${random_string.timesketch-admin-user-password.result}"
}


