terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_image" "ubuntu" {
  name = "ubuntu:22.04"
}

resource "docker_container" "web_vm" {
  name    = "web-vm"
  image   = docker_image.ubuntu.image_id
  command = ["tail", "-f", "/dev/null"]

  ports {
    internal = 80
    external = 8081
  }
}
