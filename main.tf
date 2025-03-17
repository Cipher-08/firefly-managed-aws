# Define provider
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Variables for flexibility
variable "gcp_project_id" {
  description = "GCP Project ID"
  default = " 411fd6f1a80469451e9e217a86c54d3c2ab09103"
  type        = string
}

variable "gcp_region" {
  description = "Default region for resources"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "Default zone for compute instance"
  type        = string
  default     = "us-central1-a"
}

# Create VPC
resource "google_compute_network" "gcp_vpc_main" {
  name                    = "gcp-vpc-main"
  auto_create_subnetworks = false
  description             = "Main VPC network for the project"
}

# Create Subnet
resource "google_compute_subnetwork" "gcp_subnet_private" {
  name          = "gcp-subnet-private"
  network       = google_compute_network.gcp_vpc_main.id
  ip_cidr_range = "10.10.0.0/24"
  region        = var.gcp_region
  description   = "Private subnet within VPC"
}

# IAM Service Account
resource "google_service_account" "gcp_sa_compute" {
  account_id   = "gcp-sa-compute"
  display_name = "Compute Engine Service Account"
}

# IAM Role Binding for Compute Instance
resource "google_project_iam_binding" "gcp_compute_iam" {
  project = var.gcp_project_id
  role    = "roles/compute.admin"

  members = [
    "serviceAccount:${google_service_account.gcp_sa_compute.email}"
  ]
}

# Compute Engine Instance
resource "google_compute_instance" "gcp_vm_app" {
  name         = "gcp-vm-app"
  machine_type = "e2-medium"
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.gcp_vpc_main.id
    subnetwork = google_compute_subnetwork.gcp_subnet_private.id

    access_config {
      # Enables external IP
    }
  }

  service_account {
    email  = google_service_account.gcp_sa_compute.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"  # Uses OS Login instead of SSH keys
  }

  tags = ["gcp-vm", "secure"]
}

# Output External IP
output "gcp_vm_external_ip" {
  description = "Public IP of the compute instance"
  value       = google_compute_instance.gcp_vm_app.network_interface[0].access_config[0].nat_ip
}
