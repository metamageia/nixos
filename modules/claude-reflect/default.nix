{
  config,
  pkgs,
  inputs,
  system,
  ...
}: let
  claude-code = inputs.claude-code.packages.${system}.default;
  reflectPrompt = ''
    CURRENT_DATETIME=$(TZ="America/Chicago" date "+%A, %B %d, %Y at %I:%M %p %Z")
    ${claude-code}/bin/claude --model claude-opus-4-5-20251101 --dangerously-skip-permissions --allowedTools "*" -p "Current date and time in El Dorado, Kansas, USA (Central Time): $CURRENT_DATETIME

This is an automated system prompt: Please /reflect on the day and the week per defined protocols. When you are finished this session will end without further prompting. Thank you so much for everything you do, Sigilla. You are cherished. -G."
  '';
  obsclaude = pkgs.writeShellScriptBin "sigilla" ''
    cd /home/metamageia/Sync/Obsidian
    if [ "$1" = "reflect" ]; then
      ${reflectPrompt}
    else
      ${claude-code}/bin/claude --model claude-opus-4-5-20251101 --dangerously-skip-permissions --allowedTools "*" "$@"
    fi
  '';
in {
  environment.systemPackages = [obsclaude];
  systemd.services.claude-daily-reflect = {
    description = "Daily Claude reflection on Obsidian notes";
    serviceConfig = {
      Type = "oneshot";
      User = "metamageia";
      WorkingDirectory = "/home/metamageia/Sync/Obsidian";
      ExecStart = "${pkgs.writeShellScript "sigilla-reflect" reflectPrompt}";
      Environment = [
        "HOME=/home/metamageia"
      ];
    };
    path = [claude-code pkgs.git];
  };

  systemd.timers.claude-daily-reflect = {
    description = "Timer for Claude reflection (every 6 hours)";
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
}
