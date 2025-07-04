{config, pkgs, hostName, ... }:
{

  networking.hostName = hostName; 
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  # Enable and configure Avahi for mDNS support
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
    fallbackDns = [ "8.8.8.8" ];  
  };
}

