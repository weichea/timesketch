data "template_file" "analyst-workstation-startup-script" {
  template = "${file("${path.module}/startup_scripts/analyst-workstation.sh")}"
  vars {
    grr_server_host           = "${google_compute_address.grr-server-address.address}"
    grr_admin_user            = "${var.grr_admin_user}"
    grr_admin_password        = "${random_string.grr-admin-user-password.result}"
    timesketch_admin_user     = "${var.timesketch_admin_user}"
    timesketch_admin_password = "${random_string.timesketch-admin-user-password.result}"
    timesketch_server_host    = "${google_compute_address.timesketch-server-address.address}"
  }
}

resource "google_compute_instance" "analyst-workstation" {
  count         = "${var.analyst_workstation_count}"
  name          = "analyst-workstation-${count.index}"
  machine_type  = "${var.analyst_workstation_machine_type}"
  zone          = "${var.gcp_zone}"

  # Allow to stop/start the machine to enable change machine type.
  allow_stopping_for_update = true

  # Use default Ubuntu image as operating system.
  boot_disk {
    initialize_params {
      image = "${var.gcp_ubuntu_1604_image}"
    }
  }

  # Assign a generated public IP address. Needed for SSH access.
  network_interface {
    network       = "default"
    access_config = {}
  }

  # Tag for service enumeration.
  tags = ["allow-external-ssh"]

  service_account {
    scopes = ["storage-ro", "compute-ro"]
  }

  # Provision the machine with a script.
  metadata_startup_script = "${data.template_file.analyst-workstation-startup-script.rendered}"
}