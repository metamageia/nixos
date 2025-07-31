{
  config,
  pkgs,
  inputs,
  ...
}: {
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [gutenprint];
}
