{
  pkgs,
  config,
  inputs,
  ...
}: {
  services.ollama.enable = true;
  services.ollama.package = pkgs.ollama-cuda;

  services.open-webui.enable = true;

  environment.systemPackages = with pkgs; [
    whichllm
  ];
}
