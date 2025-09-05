{
  config,
  pkgs,
  ...
}: {

environment.systemPackages = with pkgs; [
    cloudflared
  ];

}