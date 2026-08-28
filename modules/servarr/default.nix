# Servarr *arr stack for saiadha — LOCAL-FIRST media automation.
#
# This module sets up the local library + download directories, enables the
# docker runtime, and wires the *arr docker-compose stack (prowlarr, sonarr,
# radarr, jellyseerr, qbittorrent) through compose2nix so each container is a
# NixOS-managed systemd unit.
#
# The container/systemd units themselves live in ./generated.nix — produced by
# compose2nix from ./docker-compose.yaml. Regenerate after editing the compose
# file with:
#   nix run github:aksiksi/compose2nix -- \
#     -inputs modules/servarr/docker-compose.yaml \
#     -output modules/servarr/generated.nix \
#     -project servarr -runtime docker -write_nix_setup=false
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

  # UUID of the single ext4 "media-pool" partition on the dedicated 7.3 TB
  # disk (/dev/sdb) AFTER the operator's interactive wipe+format. Replace this
  # placeholder with `blkid -s UUID -o value /dev/sdb1`, then re-run
  # `nixos-rebuild build` and switch. (All-zero UUID marks it as a placeholder;
  # the build will succeed but the real device will not mount until set.)
  mediaPoolUUID = "00000000-0000-0000-0000-000000000000";
in {
  imports = [
    ./generated.nix
  ];

  # Runtime for the generated oci-containers (docker, matching pihole/vrising
  # modules). compose2nix -write_nix_setup=false leaves this to us.
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers.backend = "docker";

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

  # ---------------------------------------------------------------------------
  # LOCAL MEDIA POOL — dedicated 7.3 TB disk mounted at /srv.
  #
  # Mounting at /srv (not /srv/media) puts /srv/media, /srv/downloads, and
  # /srv/servarr on the SAME filesystem, which is required for sonarr/radarr
  # hardlinks between the download dir and the library.
  #
  # Keyed by UUID so the mount follows the disk, not a kernel name. `nofail`
  # guarantees boot never hangs or fails if the pool is absent — it's media,
  # not a boot-critical volume. Ownership of the tree is set at mkfs time via
  # `mke2fs -E root_owner=1000:100`, so the pool root is already owned by
  # metamageia; the tmpfiles rules below then create the subdirs under it.
  fileSystems."/srv" = {
    device = "/dev/disk/by-uuid/${mediaPoolUUID}";
    fsType = "ext4";
    options = [
      "nofail"
      "defaults"
      # Don't block boot waiting on the device; give up after 30s.
      "x-systemd.device-timeout=30"
    ];
  };

  # Firewall holes for the *arr web UIs / qBittorrent. Ports match
  # docker-compose.yaml. (Service ports; the containers run on the bridge net.)
  networking.firewall.allowedTCPPorts = [
    9696 # prowlarr
    8989 # sonarr
    7878 # radarr
    5055 # jellyseerr
    8080 # qbittorrent web UI
    6881 # qbittorrent BT TCP
  ];
  networking.firewall.allowedUDPPorts = [
    6881 # qbittorrent BT UDP
  ];

  # Convenience: ship compose2nix + docker-compose in the system closure so the
  # generated units can be regenerated on-box.
  environment.systemPackages = with pkgs; [
    compose2nix
    docker-compose
  ];
}
