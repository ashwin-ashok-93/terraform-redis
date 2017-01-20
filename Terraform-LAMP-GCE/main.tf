# See https://cloud.google.com/compute/docs/load-balancing/network/example

variable "install_script_src_path" {
  description = "Path to install script within this repository"
  default     = "/data/Terraform-LAMP-GCE/InstallRedis.sh"
}

variable "install_script_dest_path" {
  description = "Path to put the install script on each destination resource"
  default     = "/tmp/InstallRedis.sh"
}

variable "client_script_src_path" {
  description = "Path to install script within this repository"
  default     = "/data/Terraform-LAMP-GCE/redis-client.py"
}

variable "client_script_dest_path" {
  description = "Path to put the install script on each destination resource"
  default     = "~/redis-client.py"
}

variable "redis_server_port" {
  description = "Path to put the install script on each destination resource"
  default     = 7000
}


variable "private_key_path" {
  description = "Path to file containing private key"
  default     = "/home/ashwin/.ssh/modables-demo-bucket"
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
  name         = "tf-redis-server"
  machine_type = "f1-micro"
  zone         = "asia-east1-a"
  tags         = ["www-node"]

  disk {
    image = "ubuntu-os-cloud/ubuntu-1404-trusty-v20170110"
  }

  network_interface {
    network = "default"

    access_config {
    #Ephemeral
    }
  }
  
    provisioner "file" {
		
	 connection {
      type        = "ssh"
      user        = "root"
      private_key = "${file("${var.private_key_path}")}"
      agent       = false
    }
      source      = "${var.install_script_src_path}"
      destination = "${var.install_script_dest_path}"
  }

  provisioner "remote-exec" {
	  connection {
      type        = "ssh"
      user        = "root"
      private_key = "${file("${var.private_key_path}")}"
      agent       = false
    }
   
     inline = ["chmod +x ${var.install_script_dest_path}",
               "${var.install_script_dest_path} ${var.redis_server_port}",
               " redis-server /etc/redis/${var.redis_server_port}.conf"]
  }


  metadata {
    ssh-keys = "root:${file("/home/ashwin/.ssh/modables-demo-bucket.pub")}"
  }
  
  #metadata_startup_script = "${file("/data/Terraform-LAMP-GCE/InstallRedis.sh")}"

  service_account {
    scopes = ["https://www.googleapis.com/auth/compute.readonly"]
  }
}

#--------------------------------------------------------------#

resource "google_compute_instance" "client" {
  name         = "tf-client"
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
		
	 connection {
      type        = "ssh"
      user        = "root"
      private_key = "${file("${var.private_key_path}")}"
      agent       = false
    }
       source      = "${var.client_script_src_path}"
       destination = "${var.client_script_dest_path}"
    
  
  }

  provisioner "remote-exec" {
	  connection {
      type        = "ssh"
      user        = "root"
      private_key = "${file("${var.private_key_path}")}"
      agent       = false
    }
   
     inline = ["sudo apt-get -y update",
                "sudo apt-get -y install python-redis",
                "touch ${var.client_script_dest_path}/log.txt",
                "python2 ${var.client_script_dest_path} ${google_compute_instance.redis-server.network_interface.0.address} ${var.redis_server_port}"
                ]
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
