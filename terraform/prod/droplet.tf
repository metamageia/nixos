resource "digitalocean_droplet" "beacon" {
  name     = "homelab-node"
  image    = digitalocean_custom_image.nixos.id
  region   = "nyc3"
  size     = "s-1vcpu-2gb"
  ssh_keys = [data.digitalocean_ssh_key.terraform.id]
}

data "digitalocean_ssh_key" "terraform" {
  name = "terraform"
  public_key = file("~/.ssh/id_ed25519.pub")
}
