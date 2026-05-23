{
  inputs,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../common.nix

    ../../desktop-presets/niri

    ../../nvidia
    #../../k3s/agent.nix
    ../../nebula/node.nix

    #../../jellyfin
    #../../comfyui

    #../../virt-manager

    # Users
    ../../users/metamageia

  ];
  environment.systemPackages = with pkgs; [
    #adwaita-icon-theme
    #speex
    #libtheora
    #libgudev
    #libvdpau
  ];

  hardware.graphics.enable32Bit = true;
}
