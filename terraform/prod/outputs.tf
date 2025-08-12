output "homelab_machines" {
  value = {
    homelab-control = {
      ip   = digitalocean_droplet.homelab-control.ipv4_address
      role = "control"
    }
  }
}
