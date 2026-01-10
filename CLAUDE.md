# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a NixOS flake managing a personal cluster of machines (desktops, servers, and mobile). The flake defines configurations for multiple hosts connected via a Nebula mesh VPN.

## Common Commands

```bash
# Rebuild and switch to new configuration (preferred method via nh)
nh os switch

# Build without switching
nh os build

# Format Nix files (uses alejandra)
alejandra .

# Enter development shell (loads terraform, doctl, sops, etc.)
nix develop

# Build DigitalOcean image
nix build .#do
```

### Terraform (from dev shell)
```bash
cd terraform/prod
terraform init
terraform plan
terraform apply
```

## Architecture

### Hosts
- **argosy** - Desktop workstation
- **auriga** - Desktop/workstation with k3s agent capability
- **saiadha** - Desktop with niri compositor, nvidia, jellyfin
- **beacon** - DigitalOcean droplet, Nebula lighthouse, reverse proxy via Caddy
- **phone** - nix-on-droid configuration (aarch64)

### Module Structure
- `modules/common.nix` - Base config imported by all hosts (networking, locale, cachix, sops)
- `modules/hosts/<hostname>/` - Host-specific configs with hardware-configuration.nix
- `modules/desktop-presets/` - Desktop environment bundles (niri, plasma)
- `modules/desktop-presets/niri/` - Niri compositor + sddm + fuzzel launcher
- `modules/users/metamageia/` - User configuration and home-manager

### Key Infrastructure Modules
- `modules/nebula/` - Mesh VPN (lighthouse.nix for beacon, node.nix for others)
- `modules/comin/` - GitOps continuous deployment from this repo
- `modules/k3s/` - Kubernetes (initServer, server, agent, single node configs)
- `modules/sops/` - Secrets management (age keys at /etc/sops/age/keys.txt)

### Flake Inputs
Notable inputs: home-manager, niri-flake, comin (GitOps), sops-nix, stylix (theming), zen-browser, alejandra (formatter), nixos-generators, affinity-nix, claude-code

### Secrets
- Encrypted with sops-nix using age
- Secrets file: `secrets/homelab.secrets.yaml`
- Environment secrets: `secrets/homelab.secrets.env` (loaded in dev shell)

### Nebula Network
IP range 192.168.100.x:
- beacon (lighthouse): 192.168.100.1
- saiadha: 192.168.100.2
- auriga: 192.168.100.3
- phone: 192.168.100.4
