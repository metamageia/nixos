resource "digitalocean_custom_image" "nixos" {
  name    = "nixos"
  url     = "https://channels.nixos.org/nixos-25.05/latest-nixos-minimal-x86_64-linux.iso"
  regions = ["nyc3"]
}