{
  config,
  pkgs,
  hostName,
  ...
}: {
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };
  services.resolved = {
    enable = true;
    fallbackDns = ["8.8.8.8"];
  };
}
