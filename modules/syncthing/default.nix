{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    syncthing
  ];

  services = {
    syncthing = {
      enable = true;
      user = "metamageia";
      configDir = "/home/metamageia/Documents/.config/syncthing";
      openDefaultPorts = true;
      devices = {
      #"auriga" = { id = "DEVICE-ID-GOES-HERE"; };
      "saiadha" = { id = "FONRABV-HJBZQNY-J2CQVV2-PO53IEP-YRKGCP4-TCFEIAM-EGF5O3M-ZIP4BQY"; };
      #"phone" = { id = "DEVICE-ID-GOES-HERE"; };
    };
    };
  };
}
