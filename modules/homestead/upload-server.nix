{
  config,
  pkgs,
  ...
}: let
  pythonEnv = pkgs.python3.withPackages (ps:
    with ps; [
      psycopg2
    ]);
  uploadServer = pkgs.writeScriptBin "homestead-upload-server" ''
    #!${pythonEnv}/bin/python3
    ${builtins.readFile ./upload-server.py}
  '';
in {
  systemd.services.homestead-upload = {
    description = "Homestead server";
    after = ["postgresql.service" "postgresql-setup.service" "network.target"];
    requires = ["postgresql.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "simple";
      User = "homestead";
      Group = "homestead";
      ExecStart = "${uploadServer}/bin/homestead-upload-server";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  networking.firewall.allowedTCPPorts = [3001];
}
