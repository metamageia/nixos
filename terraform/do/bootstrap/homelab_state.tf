resource "digitalocean_spaces_bucket" "homelab_state" {
  name   = "homelab-state"
  region = "nyc3"
}

