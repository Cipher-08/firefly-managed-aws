# Define provider
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Variables for flexibility
variable "gcp_project_id" {
  description = "GCP Project ID"
  default = " 411fd6f1a80469451e9e217a86c54d3c2ab09103 "
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
resource "google_compute_network" "gcp-vpc-main" {
  name                    = "gcp-vpc-main"
  auto_create_subnetworks = false
  description             = "Main VPC network for the project"
}

# Create Subnet
resource "google_compute_subnetwork" "gcp-subnet-private" {
  name          = "gcp-subnet-private"
  network       = google_compute_network.gcp-vpc-main.id
  ip_cidr_range = "10.10.0.0/24"
  region        = var.gcp_region
  description   = "Private subnet within VPC"
}

# Compute Engine Instance
resource "google_compute_instance" "gcp-vm-app" {
  name         = "gcp-vm-app"
  machine_type = "e2-medium"
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.gcp-vpc-main.id
    subnetwork = google_compute_subnetwork.gcp-subnet-private.id

    access_config {
      # Enables external IP
    }
  }

  metadata = {
    ssh-keys = "your-username:${file("~/.ssh/id_rsa.pub")}"
  }

  tags = ["gcp-vm", "webserver"]
}

# Output External IP
output "gcp_vm_external_ip" {
  description = "Public IP of the compute instance"
  value       = google_compute_instance.gcp-vm-app.network_interface[0].access_config[0].nat_ip
}
