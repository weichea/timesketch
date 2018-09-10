# Name of GCP project to deply in
gcp_project = "YOUR GCP PROJECT NAME"

# Choose what region to deploy in.

# EU
#gcp_region  = "europe-west1"
#gcp_zone    = "europe-west1-b"

# US
gcp_region  = "us-central1"
gcp_zone    = "us-central1-f"

# How many nodes in the Elasticsearch cluster. You can have a single node cluster if this is only a test. Otherwise
# a three node cluster is probably better.
elasticsearch_node_count = 1

# How many analyst workstations should be created, if any.
analyst_workstation_count = 1

# Choose GRR and Timesketch admin usernames
grr_admin_user = "admin"
timesketch_admin_user = "admin"
