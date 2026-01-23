{
  inputs,
  system,
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

    # Services
    ../../claude-reflect
    ../../ollama
    #../../open-webui
    # ../../comfyui.nix
  ];
  environment.systemPackages = [
    inputs.opencode-flake.packages.${pkgs.system}.default
  ];
  # Enable Ollama and the Web UI on this host
  services.localOllama.enable = true;
  # Use a conversational, lower-latency model that's better for persona work
  # (Gemma 3 — 4B). Change this if you want a different local model.
  services.localOllama.defaultModel = "gemma3";

  #services.openWebUI.enable = true;

  # If you want the Web UI reachable from other LAN hosts, add the port here.
  # By default it's bound to 127.0.0.1 for safety.
  # networking.firewall.allowedTCPPorts = [ 3000 ];
}
