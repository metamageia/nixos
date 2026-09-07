{
  config,
  pkgs,
  inputs,
  userValues,
  hostName,
  ...
}: {
  imports = [
    ../../home-manager
    ../../syncthing
  ];
  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
      inherit userValues;
      inherit hostName;
    };
    users = {metamageia = import ./home.nix;};
  };

  sops.secrets = {
    "passwords/metamageia" = {
      neededForUsers = true;
      sopsFile = userValues.sopsFile;
    };
  };

  users.users.metamageia = {
    isNormalUser = true;
    description = "Metamageia";
    extraGroups = ["networkmanager" "wheel" "docker" "video" "render" "cdrom"];
    hashedPasswordFile = config.sops.secrets."passwords/metamageia".path;
    packages = with pkgs; [
    ];
  };

  programs.git = {
      enable = true;
      config.user = {
        name  = "Metamageia";
        email = "metamageia@gmail.com";
      };
    };

}
