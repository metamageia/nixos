{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  environment.systemPackages = with pkgs; [
    sops
    age
  ];
  sops.age.keyFile = "/etc/sops/age/keys.txt";
  sops.validateSopsFiles = false;
}
