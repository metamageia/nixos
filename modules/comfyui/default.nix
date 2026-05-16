{
  config,
  pkgs,
  lib,
  ...
}: let
  dataRoot = "/home/metamageia/comfyui";
  owner = "metamageia";
  group = "users";

  # Pinned image tag — bump intentionally to update.
  # yanwk image owns the whole layout under /root; first boot clones
  # ComfyUI + Manager into /root/ComfyUI and downloads default models.
  image = "yanwk/comfyui-boot:cu124-megapak";

  bindAddr = "192.168.100.2";
  port = 8188;
in {
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers.backend = "docker";

  hardware.nvidia-container-toolkit.enable = true;

  users.users.${owner}.extraGroups = ["docker"];

  systemd.tmpfiles.rules = [
    "d ${dataRoot} 0755 ${owner} ${group} - -"
  ];

  virtualisation.oci-containers.containers.comfyui = {
    inherit image;
    autoStart = true;
    ports = ["${bindAddr}:${toString port}:8188"];
    environment = {
      CLI_ARGS = "--listen 0.0.0.0 --port 8188 --normalvram";
    };
    volumes = [
      "${dataRoot}:/root"
    ];
    extraOptions = [
      "--device=nvidia.com/gpu=all"
    ];
  };
}
