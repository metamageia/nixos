{pkgs, ...}:

{
  # Enable syncthing on startup
  services = {
    syncthing = {
        enable = true;
        user = "metamageia";
        # dataDir = "/home/gage/Documents";    # Default folder for new synced f>
        configDir = "/home/metamageia/Documents/.config/syncthing";   # Folder for Syn>
    };
  };


  # Install syncthing
  environment.systemPackages = with pkgs; [
    syncthing
  ];


}
