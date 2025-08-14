resource "digitalocean_custom_image" "nixos" {
  name    = "nixos"
  url     = "https://github.com/metamageia/nixos/releases/download/nixos-unstable/nixos.x86_64-linux.do.gz"
  regions = ["nyc3"]
}