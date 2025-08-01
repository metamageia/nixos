{
  config,
  pkgs,
  inputs,
  ...
}: let
  secretsFile = ../../secrets/secrets.yaml;
  ageKeyFile = "${builtins.getEnv "HOME"}/.config/sops/age/keys.txt";
in {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  environment.systemPackages = with pkgs; [
    sops
  ];

  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  sops.age.keyFile = "/home/metamageia/.config/sops/age/keys.txt";
}
