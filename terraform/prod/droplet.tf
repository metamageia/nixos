resource "digitalocean_droplet" "beacon" {
  name     = "homelab-node"
  image    = digitalocean_custom_image.nixos.id
  region   = "nyc3"
  size     = "s-1vcpu-2gb"
  ssh_keys = [data.digitalocean_ssh_key.metamageia.id]

  connection {
    host        = self.ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = var.pvt_key
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "nixos-rebuild switch --flake github:metamageia/nixos#beacon",
    ]
  }
}

data "digitalocean_ssh_key" "metamageia" {
  name = "metamageia"
}
