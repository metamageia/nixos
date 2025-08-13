resource "digitalocean_droplet" "beacon" {
  name     = "homelab-node"
  image    = "191915724"
  region   = "nyc3"
  size     = "s-1vcpu-2gb"
  ssh_keys = [data.digitalocean_ssh_key.terraform.id]

  connection {
    host        = self.ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = var.pvt_key
    timeout     = "2m"
  }
}

