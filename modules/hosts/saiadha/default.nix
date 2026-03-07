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

    #../../docker
    #../../pihole
    ../../jellyfin

    #../../cloudflared
    ../../virt-manager

    # Users
    ../../users/metamageia

  ];
  environment.systemPackages = with pkgs; [
    inputs.opencode-flake.packages.${pkgs.stdenv.hostPlatform.system}.default
    github-copilot-cli
    adwaita-icon-theme
    speex
    libtheora
    libgudev
    libvdpau
  ];

  hardware.graphics.enable32Bit = true;
}
