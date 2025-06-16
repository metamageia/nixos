{ config, pkgs, lib, wallpaper, ... }:

{
  services.xserver.enable = true;

  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  # Replace GDM background using override with a shell script
  systemd.services.gdm-post-wallpaper = {
    wantedBy = [ "display-manager.service" ];
    after = [ "display-manager.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "gdm-set-wallpaper" ''
        mkdir -p /var/lib/gdm
        cp ${wallpaper} /var/lib/gdm/greeter-background.jpg
        chown gdm:gdm /var/lib/gdm/greeter-background.jpg
      '';
    };
  };

  # Set the GSettings override for the GDM greeter
  environment.etc."gdm/greeter.dconf-defaults".text = ''
    [org/gnome/desktop/background]
    picture-uri='file:///var/lib/gdm/greeter-background.jpg'
    picture-options='zoom'
    color-shading-type='solid'
    primary-color='#000000'
  '';

  # Ensure dconf settings are applied
  systemd.services.gdm-settings = {
    wantedBy = [ "display-manager.service" ];
    after = [ "gdm.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "apply-gdm-settings" ''
        ${pkgs.dconf}/bin/dconf update
      '';
    };
  };
}
