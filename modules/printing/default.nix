{
  config,
  pkgs,
  inputs,
  ...
}: {
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [gutenprint];

  # WebUI: http://localhost:631

  environment.systemPackages = [
    pkgs.kdePackages.okular
  ];
}
