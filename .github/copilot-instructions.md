# Copilot / AI Agent Instructions for this repository ✅

## Purpose
This repo is a personal Nix flake that manages multiple hosts, a small k3s cluster, and provisioning on DigitalOcean. Use this file to orient AI agents to the *concrete* build, deployment and editing patterns in this repository (not generic advice).

## Big picture (what to know fast) 🔧
- This is a Nix flake (see `flake.nix`) that configures multiple hosts via `modules/` and per-host files under `modules/hosts/`.
- Key subsystems:
  - **System configuration**: `modules/*` and `modules/hosts/<host>/` (NixOS modules pattern).
  - **VPN / Mesh**: Nebula in `modules/nebula/*` (certs are sops-encrypted — see `secrets/`).
  - **Kubernetes**: `modules/k3s/*` + `k3s/apps/` (kustomize-based app manifests, e.g. `k3s/apps/jellyfin`).
  - **GitOps**: `modules/comin/` and `k3s/bootstrap/fluxcd/` (Flux/GitRepository points to a homelab repo).
  - **Provisioning**: Terraform in `terraform/` (DigitalOcean provider) and DO image build via `nix build` + GitHub Action.
  - **Secrets**: managed with `sops`/`age` (see `secrets/*.yaml` and CLAUDE.md entry about `/etc/sops/age/keys.txt`).

## Essential commands & workflows (exact commands) ▶️
- Enter dev shell with required tooling (terraform, sops, doctl, etc):
  - `nix develop`
- Format Nix code: `alejandra .`
- Rebuild or switch NixOS configuration (preferred helper used in this repo):
  - `nh os switch` (preferred)
  - `nh os build` (build-only)
- Build DigitalOcean image locally (matches CI):
  - `nix build .#packages.x86_64-linux.do`
  - (CLAUDE.md also references `nix build .#do`) — CI uses `nix build .#packages.x86_64-linux.do` and uploads under tag `nixos-unstable`.
- Terraform flow (from dev shell):
  - `cd terraform/prod && terraform init && terraform plan && terraform apply`
- Kubernetes local testing:
  - KUBECONFIG path on hosts: `/etc/rancher/k3s/k3s.yaml`
  - Tooling installed by `modules/k3s`: `kubectl`, `kustomize`, `helm`.
  - Apply an app: `kubectl apply -k k3s/apps/<app>` (use host's KUBECONFIG or run on the host).
- Logs/debugging:
  - Tail k3s: `journalctl -u k3s -f`

## Project-specific conventions & patterns (copy/paste examples) 📎
- Nix modules accept `userValues` and reference `sopsFile` for secrets (example: `modules/nebula/common.nix`).
- Nebula secrets are stored via sops under `secrets/` and mounted by nix via `sops.secrets` entries (see `modules/nebula/common.nix` and `modules/k3s/common.nix`).
- Add a K8s app by creating `k3s/apps/<name>/` with a `kustomization.yaml` (see `k3s/apps/jellyfin/kustomization.yaml` and `k3s/apps/linkding/`).
- The repo contains a helper program `nh` enabled by `modules/nh/default.nix` — prefer `nh os switch` to deploy host changes.
- GitOps bootstrapping for Flux is under `k3s/bootstrap/fluxcd/` — `repo.yaml` points Flux to the external homelab repo.

## Integration points & secrets ⚠️
- DigitalOcean: Terraform in `terraform/prod` uses `var.do_token` (sensitive) to interact with DO.
- GitHub Actions & image build: `.github/workflows/build-image-nixos-digitalocean.yaml` builds and uploads a DO image; the workflow is triggered for tag `nixos-unstable`.
- Secrets: `sops` + `age`—encrypted files in `secrets/` (e.g., `secrets/homelab.secrets.yaml`); dev shell loads `secrets/homelab.secrets.env` when appropriate.

## What to change and where (common tasks) ✏️
- Add a host: create `modules/hosts/<hostname>/default.nix` and follow the pattern in existing hosts.
- Add a system-level module: create `modules/<feature>/default.nix` and import it from target hosts.
- Add a k8s app: create `k3s/apps/<app>/` with `deploy.yaml`, `service.yaml`, `ingress.yaml`, and `kustomization.yaml`; then ensure higher-level `kustomization.yaml` includes it.
- Update secrets: edit `secrets/*.yaml` and encrypt with `sops` (ensure correct age key is used by the environment).
- Format changes before PR: run `alejandra .` and ensure Nix builds (`nix build` or `nh os build`) succeed for the affected host/flake outputs.

## Files to reference when answering code or PR tasks 🔍
- `CLAUDE.md` — existing agent guidance and high-level commands
- `flake.nix`, `modules/` — core configuration
- `modules/nh/default.nix`, `modules/nebula/*`, `modules/k3s/*`
- `k3s/apps/` — concrete k8s examples (jellyfin, linkding, vrising)
- `terraform/` — DO provisioning
- `secrets/` — sops encrypted secrets
- `.github/workflows/build-image-nixos-digitalocean.yaml` — CI image build example

---
If anything is unclear or you'd like more examples (e.g., an example PR that adds a k3s app end-to-end), tell me which section to expand and I can iterate. ✅
