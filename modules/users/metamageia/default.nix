{
  config,
  pkgs,
  inputs,
  userValues,
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
      inherit userValues;
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
    extraGroups = ["networkmanager" "wheel" "docker"];
    hashedPasswordFile = config.sops.secrets."passwords/metamageia".path;
    packages = with pkgs; [
    ];
  };
}
