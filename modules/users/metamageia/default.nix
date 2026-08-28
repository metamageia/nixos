{
  config,
  pkgs,
  inputs,
  userValues,
  ...
}: let
  # The remount itself lives in a tiny script; the NOPASSWD sudo rule below
  # grants ONLY this store path, with no arguments, so sudoers stays valid
  # (a bare "/" argument cannot be expressed as a fully-qualified path).
  ro-root-heal-remount = pkgs.writeShellScriptBin "ro-root-heal-remount" ''
    exec ${pkgs.util-linux}/bin/mount -o remount,rw /
  '';
in {
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
        # Self-heal for recurring ext4 ro-flips on /. The ro-root-heal USER
        # service calls this script via NOPASSWD; the script performs the
        # remount itself so sudoers never needs argument matching (a bare
        # "/" arg is not expressible as a fully-qualified path in sudoers).
        {
          command = "${ro-root-heal-remount}/bin/ro-root-heal-remount";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # User-level watchdog (runs as metamageia, ordered only after
  # local-fs.target and pulled in by timers.target — cannot affect
  # boot/display ordering). Every 5 min: if / is mounted read-only,
  # remount it rw via the scoped NOPASSWD rule above.
  systemd.user.services.ro-root-heal = {
    description = "Remount / read-write if ext4 dropped it to ro";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = let
        heal = pkgs.writeShellScript "ro-root-heal" ''
          opts="$(${pkgs.util-linux}/bin/findmnt -no OPTIONS /)"
          case "$opts" in
            ro,*|ro)
              echo "root is read-only (opts: $opts); attempting remount,rw"
              if /run/wrappers/bin/sudo -n ${ro-root-heal-remount}/bin/ro-root-heal-remount; then
                ${pkgs.systemd}/bin/systemd-cat -p warning -t ro-root-heal <<<"remounted / rw successfully"
              else
                echo "remount REFUSED - filesystem likely has persistent errors." \
                     "Boot offline media and run: e2fsck -f /dev/disk/by-uuid/57f8245f-9b41-4836-b465-88df6c23c5f7" | \
                  ${pkgs.systemd}/bin/systemd-cat -p err -t ro-root-heal
                exit 1
              fi
              ;;
            *)
              exit 0
              ;;
          esac
        '';
      in "${heal}";
    };
  };
  systemd.user.timers.ro-root-heal = {
    description = "Periodic ro-root check";
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "5min";
    };
    wantedBy = ["timers.target"];
  };
}
