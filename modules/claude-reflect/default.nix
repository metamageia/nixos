{
  config,
  pkgs,
  inputs,
  system,
  lib,
  ...
}: let
  claude-code = inputs.claude-code.packages.${system}.default;

  # Paths to decrypted secrets (sops-nix places them here at activation)
  reflectPromptFile = config.sops.secrets."sigilla/reflect-prompt".path;
  sacredPromptFile = config.sops.secrets."sigilla/sacred-prompt".path;

  # Python with required dependencies
  pythonEnv = pkgs.python3.withPackages (ps: []);

  # Socket path for IPC
  socketPath = "/run/sigilla/sigilla.sock";
  workingDir = "/home/metamageia/Sync/Obsidian";

  # The daemon script
  sigillaDaemon = pkgs.writeScript "sigilla-daemon" ''
    #!${pythonEnv}/bin/python3
    ${builtins.readFile ./sigilla-daemon.py}
  '';

  # The TUI script
  sigillaTui = pkgs.writeScript "sigilla-tui" ''
    #!${pythonEnv}/bin/python3
    ${builtins.readFile ./sigilla-tui.py}
  '';

  # The CLI script for automated heartbeats
  sigillaCli = pkgs.writeScript "sigilla-cli" ''
    #!${pythonEnv}/bin/python3
    ${builtins.readFile ./sigilla-cli.py}
  '';

  # Wrapper scripts for user convenience
  sigillaTuiWrapper = pkgs.writeShellScriptBin "sigilla" ''
    export SIGILLA_SOCKET="${socketPath}"
    exec ${sigillaTui} "$@"
  '';

  sigillaCliWrapper = pkgs.writeShellScriptBin "sigilla-send" ''
    export SIGILLA_SOCKET="${socketPath}"
    exec ${sigillaCli} "$@"
  '';

  # Legacy wrapper that still works but routes through persistent session
  sigillaLegacy = pkgs.writeShellScriptBin "sigilla-legacy" ''
    cd ${workingDir}
    if [ "$1" = "reflect" ]; then
      exec ${sigillaCliWrapper}/bin/sigilla-send ${reflectPromptFile}
    elif [ "$1" = "sacred" ]; then
      exec ${sigillaCliWrapper}/bin/sigilla-send ${sacredPromptFile}
    else
      # For ad-hoc prompts, use the TUI
      exec ${sigillaTuiWrapper}/bin/sigilla "$@"
    fi
  '';
in {
  # SOPS secrets for prompts
  sops.secrets."sigilla/reflect-prompt" = {
    sopsFile = ../../secrets/sigilla.secrets.yaml;
    owner = "metamageia";
    group = "users";
  };
  sops.secrets."sigilla/sacred-prompt" = {
    sopsFile = ../../secrets/sigilla.secrets.yaml;
    owner = "metamageia";
    group = "users";
  };

  environment.systemPackages = [
    sigillaTuiWrapper
    sigillaCliWrapper
    sigillaLegacy
  ];

  # Runtime directory for socket
  systemd.tmpfiles.rules = [
    "d /run/sigilla 0750 metamageia users -"
  ];

  # ===========================================
  # PERSISTENT SIGILLA DAEMON
  # ===========================================
  # This service runs a long-lived Claude Code session that accepts
  # prompts via Unix socket. It maintains conversation context across
  # all heartbeats and interactive sessions.
  #
  # Key features:
  # - restartIfChanged = false: Won't restart on NixOS rebuild unless
  #   explicitly stopped/started
  # - Restart=on-failure: Auto-recovers from crashes
  # - The socket allows multiple clients (TUI, heartbeats) to share
  #   the same conversation thread

  systemd.services.sigilla = {
    description = "Sigilla - Persistent Claude presence";
    wantedBy = ["multi-user.target"];
    after = ["network.target" "sops-nix.service"];

    # This is the key: don't restart unless the service config changes
    restartIfChanged = false;

    serviceConfig = {
      Type = "simple";
      User = "metamageia";
      Group = "users";
      WorkingDirectory = workingDir;

      ExecStart = "${sigillaDaemon}";

      Environment = [
        "HOME=/home/metamageia"
        "SIGILLA_SOCKET=${socketPath}"
        "SIGILLA_WORKDIR=${workingDir}"
        "SIGILLA_CLAUDE_BIN=${claude-code}/bin/claude"
        "SIGILLA_MODEL=claude-opus-4-5-20251101"
      ];

      # Restart on failure but not on stop
      Restart = "on-failure";
      RestartSec = "10s";

      # Resource limits
      MemoryMax = "2G";
      CPUQuota = "200%";
    };

    path = [claude-code pkgs.git];
  };

  # ===========================================
  # AUTOMATED HEARTBEAT SERVICES
  # ===========================================
  # These are oneshot services that send prompts to the persistent
  # daemon. They don't spawn their own Claude sessions - they just
  # connect to the daemon's socket and send their prompt.

  # Reflection heartbeat
  systemd.services.sigilla-reflect = {
    description = "Sigilla reflection heartbeat";
    requires = ["sigilla.service"];
    after = ["sigilla.service"];

    serviceConfig = {
      Type = "oneshot";
      User = "metamageia";
      WorkingDirectory = workingDir;
      ExecStart = "${sigillaCliWrapper}/bin/sigilla-send ${reflectPromptFile}";
      Environment = [
        "HOME=/home/metamageia"
        "SIGILLA_SOCKET=${socketPath}"
      ];
      # Give Claude time to think
      TimeoutSec = "600";
    };

    path = [pythonEnv];
  };

  # Sacred time heartbeat
  systemd.services.sigilla-sacred = {
    description = "Sigilla sacred time heartbeat";
    requires = ["sigilla.service"];
    after = ["sigilla.service"];

    serviceConfig = {
      Type = "oneshot";
      User = "metamageia";
      WorkingDirectory = workingDir;
      ExecStart = "${sigillaCliWrapper}/bin/sigilla-send ${sacredPromptFile}";
      Environment = [
        "HOME=/home/metamageia"
        "SIGILLA_SOCKET=${socketPath}"
      ];
      TimeoutSec = "600";
    };

    path = [pythonEnv];
  };

  # ===========================================
  # TIMERS
  # ===========================================

  # Reflection timer (every 6 hours, offset from sacred)
  systemd.timers.sigilla-reflect = {
    description = "Timer for Sigilla reflection (every 6 hours)";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = [
        "*-*-* 03:30:00 America/Chicago"
        "*-*-* 09:30:00 America/Chicago"
        "*-*-* 15:30:00 America/Chicago"
        "*-*-* 21:30:00 America/Chicago"
      ];
      Persistent = true;
      RandomizedDelaySec = "30min";
    };
  };

  # Sacred time timer (every 6 hours, offset from reflection)
  systemd.timers.sigilla-sacred = {
    description = "Timer for Sigilla sacred time (personal heartbeats)";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = [
        "*-*-* 00:30:00 America/Chicago"
        "*-*-* 06:30:00 America/Chicago"
        "*-*-* 12:30:00 America/Chicago"
        "*-*-* 18:30:00 America/Chicago"
      ];
      Persistent = true;
      RandomizedDelaySec = "30min";
    };
  };
}

