{
  config,
  pkgs,
  hostName,
  ...
}: {
  #networking.firewall.allowedTCPPorts = [5353];
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    allowInterfaces = ["eth0" "nebula.mesh"];
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };
  services.resolved = {
    enable = true;
    settings.Resolve.FallbackDNS = ["8.8.8.8"];
  };
}
