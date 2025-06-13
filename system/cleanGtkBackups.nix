{ config, lib, pkgs, ... }:
{
  system.activationScripts.cleanupGtkBackups = {
    text = ''
      find /home/${config.users.users.metamageia.name}/.config/gtk-* \
        -name '*.backup' -delete || true
    '';
    order = "99-cleanup-gtk-backups";
  };
}
