{pkgs, inputs, ...}: {
  imports = [
    inputs.nixcord.homeModules.nixcord
  ];
  home.Packages = with pkgs; [
    discord
    vencord
  ];
}
