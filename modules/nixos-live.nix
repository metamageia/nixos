{ config, pkgs, lib, ... }:

{
  isoImage.isoName = lib.mkDefault "nixos-live.iso";
  environment.etc."nixos".source = ./.;

  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.device = "nodev";  

  boot.supportedFilesystems = [ "btrfs" "ext4" "xfs" "zfs" ];
  boot.zfs.enable = true;

  hardware.enableRedistributableFirmware = true;

  environment.systemPackages = with pkgs; [
    pciutils usbutils
    parted gptfdisk
    btrfs-progs
    e2fsprogs 
    dosfstools
    nixos-install
    nixos-generate-config
  ];

  users.users.root.initialPassword = "nixos";

}
