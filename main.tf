variable "gcp_service_account_key" {
  description = "Base64 encoded GCP service account key"
  type        = string
  sensitive   = true
}

provider "google" {
  credentials = jsondecode(base64decode(var.gcp_service_account_key))
  project     = "content-gen-418510"
  region      = "us-central1"
}

# Variables for flexibility
variable "gcp_project_id" {
  description = "GCP Project ID"
  default = " 411fd6f1a80469451e9e217a86c54d3c2ab09103"
  type        = string
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

# 1. Create VPC
resource "google_compute_network" "gcp_vpc_main" {
  name                    = "gcp-vpc-main"
  auto_create_subnetworks = false
  description             = "Main VPC network for the project"
}

# 2. Create Subnet (Depends on VPC)
resource "google_compute_subnetwork" "gcp_subnet_private" {
  name          = "gcp-subnet-private"
  network       = google_compute_network.gcp_vpc_main.id
  ip_cidr_range = "10.10.0.0/24"
  region        = var.gcp_region
  description   = "Private subnet within VPC"
}

# 3. Create IAM Service Account (Depends on VPC)
resource "google_service_account" "gcp_sa_compute" {
  account_id   = "gcp-sa-compute"
  display_name = "Compute Engine Service Account"
  depends_on   = [google_compute_network.gcp_vpc_main]
}

# 4. Attach IAM Role to Service Account (Depends on SA)
resource "google_project_iam_binding" "gcp_compute_iam" {
  project = var.gcp_project_id
  role    = "roles/compute.admin"

  members = [
    "serviceAccount:${google_service_account.gcp_sa_compute.email}"
  ]

  depends_on = [google_service_account.gcp_sa_compute]
}

# 5. Compute Instance (Depends on IAM and Network)
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
    enable-oslogin = "TRUE"
  }

  tags = ["gcp-vm", "secure"]

  depends_on = [
    google_compute_network.gcp_vpc_main,
    google_compute_subnetwork.gcp_subnet_private,
    google_project_iam_binding.gcp_compute_iam
  ]
}

# 6. Output External IP
output "gcp_vm_external_ip" {
  description = "Public IP of the compute instance"
  value       = google_compute_instance.gcp_vm_app.network_interface[0].access_config[0].nat_ip
}
