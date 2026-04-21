{
  config,
  pkgs,
  ...
}: let
  pythonEnv = pkgs.python3.withPackages (ps:
    with ps; [
      psycopg2
      pillow
    ]);
  processor = pkgs.writeScriptBin "homestead-processor" ''
    #!${pythonEnv}/bin/python3
    ${builtins.readFile ./processor.py}
  '';
in {
  systemd.services.homestead-processor = {
    description = "Homestead screenshot OCR processor";
    after = ["postgresql.service" "postgresql-setup.service"];
    requires = ["postgresql.service"];
    path = [pkgs.tesseract];
    serviceConfig = {
      Type = "oneshot";
      User = "homestead";
      Group = "homestead";
      ExecStart = "${processor}/bin/homestead-processor";
      WorkingDirectory = "/var/lib/homestead";
    };
  };

  systemd.timers.homestead-processor = {
    description = "Run homestead processor every 5 minutes";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "5min";
      Persistent = true;
    };
  };
}
