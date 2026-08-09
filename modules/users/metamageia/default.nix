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

  # Passwordless rebuilds for the Hermes agent. The terminal sandbox keeps
  # /nix and /run read-only, so activations run via systemd-run --user
  # (real namespace); these rules let that sudo succeed without a prompt.
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
        # nh calls sudo itself; name the binary so `nh os switch` runs unprompted.
        {
          command = "/run/current-system/sw/bin/nh *";
          options = [ "NOPASSWD" ];
        }
        # nh builds the system itself, then activates directly — it execs
        # `sudo env <vars> /nix/store/<gen>/bin/switch-to-configuration
        # <test|switch>`. First token is env, binary is the per-generation
        # store path of switch-to-configuration, NOT nixos-rebuild. sudo
        # resolves `env` via the invoking shell's PATH; the agent's shells
        # lead with /run/current-system/sw/bin. Root-equivalent either way
        # (a malicious flake runs as root at switch), so no real exposure.
        {
          command = "/run/current-system/sw/bin/env */nix/store/*/bin/switch-to-configuration *";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
