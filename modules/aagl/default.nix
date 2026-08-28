{
  inputs,
  ...
}: {
  imports = [
    inputs.aagl.nixosModules.default
  ];

  # Cachix for ezkea's prebuilt launchers (declarative setup per upstream README).
  nix.settings = inputs.aagl.nixConfig;

  programs.honkers-railway-launcher.enable = true;
  programs.wavey-launcher.enable = true;
}
