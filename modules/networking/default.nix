{
  config,
  pkgs,
  hostName,
  ...
}: {
  imports = [
    ../avahi
    ../openssh
  ];

  environment.systemPackages = with pkgs; [
    # Standalone wifi GUI, launchable from fuzzel (full window, no tray).
    # Talks to iwd directly, which is the NetworkManager wifi backend here, so
    # it sees the same connections NetworkManager manages. (nm-applet is the
    # tray-only alternative; iwgtk fits the current no-tray fuzzel workflow.)
    iwgtk
  ];

  networking = {
    hostName = hostName;
    wireless.iwd.enable = true;
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
      # Disable wifi power-save: the broadcom-sta (wl) driver on setseke drops
      # the link when the NIC enters power-save — the primary cause of the
      # random disconnects. false turns power-save off outright.
      wifi.powersave = false;
    };

    firewall = {
      allowedTCPPorts = [
        2379
        2380
        80
        443
      ];
      allowedUDPPorts = [
        4242
        7359
        1900
      ];
    };
  };
}
