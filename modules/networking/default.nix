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
    # Windowed NetworkManager connection GUI, launchable from fuzzel (no tray).
    # iwgtk was removed: it talks to iwd directly, but this stack runs iwd as
    # NetworkManager's backend — NM owns the iwd agent/netdev, so iwgtk's connect
    # stalls (no agent answers its credential prompt) and falls back to the list.
    # networkmanagerapplet ships BOTH `nm-applet` (the tray applet — for the
    # upcoming re-rice) and `nm-connection-editor` (a windowed editor, launch
    # from fuzzel as "nm-connection-editor"). NM-native, so it works with the
    # NM-on-iwd backend here.
    networkmanagerapplet
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
