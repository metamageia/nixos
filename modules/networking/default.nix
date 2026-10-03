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
    networkmanagerapplet
    networkmanager_dmenu
  ];

  networking = {
    hostName = hostName;
    wireless.iwd.enable = true;
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
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

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="${pkgs.iw}/bin/iw dev %k set power_save off"
    ACTION=="add", SUBSYSTEM=="net", RUN+="/bin/sh -c 'test -e /sys/class/net/%k/wireless && ${pkgs.iw}/bin/iw dev %k set power_save off'"
  '';
}
