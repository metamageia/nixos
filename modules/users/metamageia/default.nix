{
  config,
  pkgs,
  inputs,
  userValues,
  ...
}: {
  imports = [
    ../../home-manager
    ../../syncthing
    ../../desktop.nix
    #../../desktop-presets/niri
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
      sopsFile = userValues.sopsFile;
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
