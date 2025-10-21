{
  inputs,
  system,
  pkgs,
  config,
  ...
}: {
programs.virt-manager.enable = true;

users.groups.libvirtd.members = ["metamageia"];

virtualisation.libvirtd.enable = true;

virtualisation.spiceUSBRedirection.enable = true;
}