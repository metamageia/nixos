{
  config,
  pkgs,
  inputs,
  wallpaper,
  sopsFile,
  ...
}: {
  imports = [
    ../../home-manager
    ../../syncthing
  ];
  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
      inherit wallpaper;
    };
    users = {metamageia = import ./home.nix;};
  };

  sops.secrets = {
    "passwords/metamageia" = {
      neededForUsers = true;
      sopsFile = sopsFile;
    };
  };

  users.users.metamageia = {
    isNormalUser = true;
    description = "Metamageia";
    extraGroups = ["networkmanager" "wheel"];
    hashedPasswordFile = config.sops.secrets."passwords/metamageia".path;
    packages = with pkgs; [
    ];
  };
}
