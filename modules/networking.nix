{config, pkgs, hostName, ... }:
{

 networking.hostName = hostName; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_>

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";


  # Enable and configure Avahi for mDNS support
  services.avahi = {
    enable = true;                # Enable the Avahi service
    nssmdns = true;               # Enable mDNS Name Service Switch support
    publish = {
      enable = true;              # Enable publishing via mDNS
      addresses = true;           # Publish IP addresses
      workstation = true;         # Publish workstation information
    };
  };

  # Optionally, enable systemd-resolved for DNS resolution
  services.resolved = {
    enable = true;                # Enable systemd-resolved
    fallbackDns = [ "8.8.8.8" ];  # Set fallback DNS servers
  };
}

