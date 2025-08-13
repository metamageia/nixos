output "homelab_machines" {
  value = {
    beacon = {
      ip   = digitalocean_droplet.beacon.ipv4_address
      role = "control"
    }
  }
}
