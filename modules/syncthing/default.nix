{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    syncthing
  ];

  services = {
    syncthing = {
      enable = true;
      user = "metamageia";
      configDir = "/home/metamageia/Documents/.config/syncthing";
    };
  };
}
