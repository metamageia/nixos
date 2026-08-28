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
  # One master key for everything; place it at /etc/sops/age/keys.txt on
  # each machine (from the password manager) before first activation.
  sops.age.keyFile = "/etc/sops/age/keys.txt";
  sops.validateSopsFiles = false;

  # Mirror the system key into the user config so manual `sops` works.
  systemd.services.sops-user-key = {
    description = "Mirror sops age key to user config";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      keyfile=/home/metamageia/.config/sops/age/keys.txt
      if [ -d /home/metamageia ] && [ -f /etc/sops/age/keys.txt ] && [ ! -f "$keyfile" ]; then
        install -d -m 700 -o metamageia /home/metamageia/.config/sops/age
        cp /etc/sops/age/keys.txt "$keyfile"
        chown metamageia "$keyfile"
        chmod 600 "$keyfile"
      fi
    '';
  };
}
