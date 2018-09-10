variable "gcp_project"                      {}
variable "gcp_region"                       {}
variable "gcp_zone"                         {}

variable "gcp_ubuntu_1604_image"            { default = "ubuntu-os-cloud/ubuntu-1604-lts" }
variable "gcp_ubuntu_1804_image"            { default = "ubuntu-os-cloud/ubuntu-1804-lts" }

variable "timesketch_machine_type"          { default = "n1-standard-2" }
variable "timesketch_disk_size_gb"          { default = 200 }
variable "timesketch_admin_user"            { default = "admin" }

variable "elasticsearch_cluster_name"       { default = "timesketch" }
variable "elasticsearch_machine_type"       { default = "n1-highmem-4" }
variable "elasticsearch_disk_size_gb"       { default = 200 }
variable "elasticsearch_node_count"         { default = 1 }

variable "grr_machine_type"                 { default = "n1-standard-1" }
variable "grr_admin_user"                   { default = "admin" }

variable "analyst_workstation_count"        { default = 1 }
variable "analyst_workstation_machine_type" { default = "n1-standard-4" }
