{
  config,
  pkgs,
  inputs,
  userValues,
  ...
}: {
  imports = [
    ../../home-manager
    ../../syncthing
  ];
  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
      inherit userValues;
    };
    users = {metamageia = import ./home.nix;};
  };

  sops.secrets = {
    "passwords/metamageia" = {
      neededForUsers = true;
      sopsFile = userValues.sopsFile;
    };
  };

  users.users.metamageia = {
    isNormalUser = true;
    description = "Metamageia";
    extraGroups = ["networkmanager" "wheel" "docker" "video" "render" "cdrom"];
    hashedPasswordFile = config.sops.secrets."passwords/metamageia".path;
    packages = with pkgs; [
    ];
  };

  programs.git = {
      enable = true;
      config.user = {
        name  = "Metamageia";
        email = "metamageia@gmail.com";
      };
    };

  # Allow passwordless system rebuilds so the Hermes agent can run
  # `nixos-rebuild switch` (and `nh os switch`, which wraps it) unattended.
  # Required because sudo cannot prompt for a password with no TTY present.
  security.sudo.extraRules = [
    {
      users = [ "metamageia" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild switch *";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/nixos-rebuild boot *";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
