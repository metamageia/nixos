{pkgs, ...}:
{

environtment.systemPackages = with pkgs; [
  pihole
  pihole-web
];

}