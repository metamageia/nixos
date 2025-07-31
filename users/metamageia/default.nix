{
  config,
  pkgs,
  inputs,
  wallpaper,
  ...
}: {
  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
      inherit wallpaper;
    };
    users = {metamageia = import ./home.nix;};
  };

  users.users.metamageia = {
    isNormalUser = true;
    description = "Metamageia";
    extraGroups = ["networkmanager" "wheel"];
    packages = with pkgs; [
    ];
  };
}
