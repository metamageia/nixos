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
    ../../ollama
    #../../open-webui
    # ../../comfyui.nix
  ];
  environment.systemPackages = with pkgs; [
    inputs.opencode-flake.packages.${pkgs.system}.default
    github-copilot-cli
    adwaita-icon-theme
    speex
    libtheora
    libgudev
    libvdpau
  ];
  # Enable Ollama and the Web UI on this host
  services.localOllama.enable = true;
  # Qwen 2.5 7B - supports tool/function calling for agent CLIs
  # Fits in ~4.5GB VRAM on GTX 1660
  services.localOllama.defaultModel = "qwen2.5:7b";

  # Also pull the faster 3B variant
  systemd.services.ollama-pull-qwen-3b = {
    description = "Pull Qwen 2.5 3B model";
    wants = ["ollama.service"];
    after = ["ollama.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ollama}/bin/ollama pull qwen2.5:3b";
      User = "ollama";
      Group = "ollama";
      Environment = [
        "HOME=/var/lib/ollama"
        "OLLAMA_HOST=127.0.0.1:11434"
      ];
    };
    wantedBy = ["multi-user.target"];
  };

  #services.openWebUI.enable = true;

  # If you want the Web UI reachable from other LAN hosts, add the port here.
  # By default it's bound to 127.0.0.1 for safety.
  # networking.firewall.allowedTCPPorts = [ 3000 ];

  hardware.graphics.enable32Bit = true;
}
