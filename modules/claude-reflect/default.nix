{
    config,
    pkgs,
    inputs,
    system,
    ...
  }: let
    claude-code = inputs.claude-code.packages.${system}.default;

    # Paths to decrypted secrets (sops-nix places them here at activation)
    reflectPromptFile = config.sops.secrets."sigilla/reflect-prompt".path;
    sacredPromptFile = config.sops.secrets."sigilla/sacred-prompt".path;

    # Script that reads prompt from secret file at runtime
    runWithPrompt = promptFile: ''
      CURRENT_DATETIME=$(TZ="America/Chicago" date "+%A, %B %d, %Y at %I:%M %p %Z")
      PROMPT=$(cat ${promptFile})
      PROMPT_WITH_TIME="Current date and time in El Dorado, Kansas, USA (Central Time): $CURRENT_DATETIME

$PROMPT"
      ${claude-code}/bin/claude --model claude-opus-4-5-20251101 --dangerously-skip-permissions --allowedTools "*" -p "$PROMPT_WITH_TIME"
    '';

    obsclaude = pkgs.writeShellScriptBin "sigilla" ''
      cd /home/metamageia/Sync/Obsidian
      if [ "$1" = "reflect" ]; then
        ${runWithPrompt reflectPromptFile}
      elif [ "$1" = "sacred" ]; then
        ${runWithPrompt sacredPromptFile}
      else
        ${claude-code}/bin/claude --model claude-opus-4-5-20251101 --dangerously-skip-permissions --allowedTools "*" "$@"
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

    environment.systemPackages = [obsclaude];

    # Reflection service (existing)
    systemd.services.claude-daily-reflect = {
      description = "Daily Sigilla reflection on Obsidian notes";
      serviceConfig = {
        Type = "oneshot";
        User = "metamageia";
        WorkingDirectory = "/home/metamageia/Sync/Obsidian";
        ExecStart = "${pkgs.writeShellScript "sigilla-reflect" (runWithPrompt reflectPromptFile)}";
        Environment = [
          "HOME=/home/metamageia"
        ];
      };
      path = [claude-code pkgs.git];
    };

    # Sacred time service (new)
    systemd.services.claude-sacred-time = {
      description = "Sigilla sacred time - personal heartbeats";
      serviceConfig = {
        Type = "oneshot";
        User = "metamageia";
        WorkingDirectory = "/home/metamageia/Sync/Obsidian";
        ExecStart = "${pkgs.writeShellScript "sigilla-sacred" (runWithPrompt sacredPromptFile)}";
        Environment = [
          "HOME=/home/metamageia"
        ];
      };
      path = [claude-code pkgs.git];
    };

    # Reflection timer (existing)
    systemd.timers.claude-daily-reflect = {
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

    # Sacred time timer (new)
    systemd.timers.claude-sacred-time = {
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

