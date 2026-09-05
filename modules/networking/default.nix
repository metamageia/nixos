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

    # rofi-based NetworkManager frontend with FULL wifi discovery (live scan of
    # nearby networks + connect + passphrase prompt). Launch from fuzzel as
    # `networkmanager_dmenu`; no tray. The primary answer to "nm-connection-
    # editor has no discovery." (rofi-network-manager is a near-twin.)
    networkmanager_dmenu
  ];

  networking = {
    hostName = hostName;
    wireless.iwd.enable = true;
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
      # NOTE: wifi.powersave only affects the wpa_supplicant backend — with
      # wifi.backend = "iwd" it is a NO-OP (iwd owns power-save). The wl driver
      # on setseke drops the link when the NIC enters power-save, so disable it
      # with a udev rule instead (see below).
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

  # Turn off wifi power-save on every wireless NIC. The broadcom-sta (wl)
  # driver on setseke drops the link when the NIC idles into power-save —
  # the cause of the inactivity disconnects. The udev rule runs regardless
  # of which backend (NM/iwd) owns the device, and on every boot/plugin.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="${pkgs.iw}/bin/iw dev %k set power_save off"
    ACTION=="add", SUBSYSTEM=="net", RUN+="/bin/sh -c 'test -e /sys/class/net/%k/wireless && ${pkgs.iw}/bin/iw dev %k set power_save off'"
  '';
}
