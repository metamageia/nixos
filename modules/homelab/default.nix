{
  inputs,
  config,
  pkgs,
  hostName,
  sopsFile,
  ...
}: {
  imports = [
    #inputs.homelab.nixosModules.homelab
    ../k3s
    ../nebula
  ];

  environment.systemPackages = with pkgs; [qbittorrent];
}
