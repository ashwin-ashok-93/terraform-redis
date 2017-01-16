# See https://cloud.google.com/compute/docs/load-balancing/network/example


variable "install_script_src_path" {
  description = "Path to install script within this repository"
  default     = "installRedis.sh"
}

variable "install_script_dest_path" {
  description = "Path to put the install script on each destination resource"
  default     = "/home/ashwin/installRedis.sh"
}

provider "google" {
  region      = "asia-east1"
  project     = "calcium-verbena-154713"
  credentials = "${file("credentials.json")}"
}

resource "google_compute_http_health_check" "default" {
  name                = "tf-redis-basic-check"
  request_path        = "/"
  check_interval_sec  = 1
  healthy_threshold   = 1
  unhealthy_threshold = 10
  timeout_sec         = 1
}

resource "google_compute_target_pool" "default" {
  name          = "tf-redis-target-pool"
  instances     = ["${google_compute_instance.redis-server.*.self_link}",
                   "${google_compute_instance.client.*.self_link}"]
  health_checks = ["${google_compute_http_health_check.default.name}"]
}

resource "google_compute_forwarding_rule" "default" {
  name       = "tf-redis-forwarding-rule"
  target     = "${google_compute_target_pool.default.self_link}"
  port_range = "80"
}

resource "google_compute_instance" "redis-server" {
  count = 1
  name         = "tf-redis-server-${count.index}"
  machine_type = "f1-micro"
  zone         = "asia-east1-a"
  tags         = ["www-node"]

  disk {
    image = "ubuntu-os-cloud/ubuntu-1404-trusty-v20170110"
  }

  network_interface {
    network = "default"

    access_config {
      # Ephemeral
    }
  }
  
    provisioner "file" {
    source      = "${var.install_script_src_path}"
    destination = "${var.install_script_dest_path}"

  }

  provisioner "remote-exec" {
   
     inline = ["chmod +x ${var.install_script_dest_path} && sudo ${var.install_script_dest_path}"]
  }


  metadata {
    ssh-keys = "root:${file("/home/ashwin/.ssh/modables-demo-bucket.pub")}"
  }
  
  #metadata_startup_script = "${file("/data/Terraform-LAMP-GCE/InstallRedis.sh")}"

  service_account {
    scopes = ["https://www.googleapis.com/auth/compute.readonly"]
  }
}

resource "google_compute_instance" "client" {
  count = 1
  name         = "tf-client-${count.index}"
  machine_type = "f1-micro"
  zone         = "asia-east1-a"
  tags         = ["www-node"]

  disk {
    image = "ubuntu-os-cloud/ubuntu-1404-trusty-v20170110"
  }

  network_interface {
    network = "default"

    access_config {
      # Ephemeral
    }
  }

  metadata {
    ssh-keys = "root:${file("/home/ashwin/.ssh/modables-demo-bucket.pub")}"
  }
  
  service_account {
    scopes = ["https://www.googleapis.com/auth/compute.readonly"]
  }
}


resource "google_compute_firewall" "default" {
  name    = "tf-redis-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["www-node"]
}
