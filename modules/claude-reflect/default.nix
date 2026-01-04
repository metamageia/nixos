{
  config,
  pkgs,
  inputs,
  system,
  ...
}: let
  claude-code = inputs.claude-code.packages.${system}.default;
in {
  systemd.services.claude-daily-reflect = {
    description = "Daily Claude reflection on Obsidian notes";
    serviceConfig = {
      Type = "oneshot";
      User = "metamageia";
      WorkingDirectory = "/home/metamageia/Sync/Obsidian";
      ExecStart = "${pkgs.writeShellScript "claude-reflect" ''
        ${claude-code}/bin/claude --dangerously-skip-permissions --allowedTools "*" -p "This is an automated system prompt: Please /reflect on the day and the week per defined protocols. When you are finished this session will end without further prompting. Thank you so much for everything you do."
      ''}";
      Environment = [
        "HOME=/home/metamageia"
      ];
    };
    path = [claude-code pkgs.git];
  };

  systemd.timers.claude-daily-reflect = {
    description = "Timer for daily Claude reflection";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* 03:30:00 America/Chicago";
      Persistent = true;
      RandomizedDelaySec = "30min";
    };
  };
}
