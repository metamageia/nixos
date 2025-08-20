{
  config,
  system,
  pkgs,
  hostName,
  sopsFile,
  ...
}: {
  users.users.root = {
    extraGroups = ["docker"];
    hashedPassword = "";
  };

  networking.hostName = hostName;
  networking.networkmanager.enable = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];

  imports = [
    ../../common.nix
    ../../comin
    ../../k3s/single.nix
    ../../nebula/lighthouse.nix

  ];
  environment.systemPackages = with pkgs; [
    git
    nano
  ];

  swapDevices = [
    {
      device = "/swapfile";
      size = 2 * 1024;
    }
  ];

  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = null;
      UseDns = true;
      X11Forwarding = false;
      PermitRootLogin = "prohibit-password";
    };
  };
}
