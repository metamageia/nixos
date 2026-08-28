# Servarr *arr stack for saiadha — LOCAL-FIRST media automation.
#
# This module sets up the local library + download directories and wires the
# *arr docker-compose stack (prowlarr, sonarr, radarr, jellyseerr, qbittorrent)
# through compose2nix so each container is a NixOS-managed systemd unit.
#
# IMPORTANT: this module does NOT enable the containers itself. compose2nix
# generates the actual oci-containers/systemd units (referenced below). Enable
# the generated file by uncommenting the `imports` line once generated.nix
# exists (run compose2nix from modules/servarr; see docker-compose.yaml header).
#
# Deliberately out of scope for THIS run:
#   - services.jellyfin / the rclone "drive:Server_Media" mount are untouched.
#     Jellyfin repoint + rclone backup-sync are a separate follow-up deliverable.

{
  pkgs,
  lib,
  ...
}: let
  # Ownership for the local library: uid 1000 (metamageia) / gid 100 (users),
  # matching the rclone mount uid and the PUID/PGID used by the containers.
  owner = "1000";
  group = "100";
in {
  # NOTE: once you run compose2nix, uncomment to pull in the generated units:
  # imports = [ ./generated.nix ];

  # Local media library + download paths. Created at boot via tmpfiles with
  # correct ownership so the *arr containers (PUID/PGID 1000/100) can write.
  systemd.tmpfiles.rules = [
    "d /srv/media 0755 ${owner} ${group} - -"
    "d /srv/media/Movies 0775 ${owner} ${group} - -"
    "d /srv/media/TV 0775 ${owner} ${group} - -"
    "d /srv/downloads 0775 ${owner} ${group} - -"
    # Per-container /config volume roots (compose2nix mounts these read-write).
    "d /srv/servarr 0755 ${owner} ${group} - -"
    "d /srv/servarr/prowlarr/config 0775 ${owner} ${group} - -"
    "d /srv/servarr/sonarr/config 0775 ${owner} ${group} - -"
    "d /srv/servarr/radarr/config 0775 ${owner} ${group} - -"
    "d /srv/servarr/jellyseerr/config 0775 ${owner} ${group} - -"
    "d /srv/servarr/qbittorrent/config 0775 ${owner} ${group} - -"
  ];

  # Firewall holes for the *arr web UIs / qBittorrent. Ports match
  # docker-compose.yaml. (Service ports; the containers run on the bridge net.)
  networking.firewall.allowedTCPPorts = [
    9696 # prowlarr
    8989 # sonarr
    7878 # radarr
    5055 # jellyseerr
    8080 # qbittorrent web UI
    6881 # qbittorrent TCP
  ];
  networking.firewall.allowedUDPPorts = [
    6881 # qbittorrent UDP
  ];

  # Convenience: ship the compose file + compose2nix in the system closure and
  # expose a one-shot to regenerate the NixOS units.
  environment.systemPackages = with pkgs; [
    compose2nix
    docker-compose
  ];
}
