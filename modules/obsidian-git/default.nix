{pkgs, ...}: let
  gitBackupScript = pkgs.writeShellScript "obsidian-git-backup" ''
    cd /home/metamageia/Sync/Obsidian || exit 1

    # Check if it's a git repository
    if [ ! -d .git ]; then
      echo "Not a git repository, initializing..."
      ${pkgs.git}/bin/git init
    fi

    # Check for changes
    if [ -n "$(${pkgs.git}/bin/git status --porcelain)" ]; then
      ${pkgs.git}/bin/git add -A
      ${pkgs.git}/bin/git commit -m "Auto-backup: $(date '+%Y-%m-%d %H:%M:%S')"

      # Push if remote exists
      if ${pkgs.git}/bin/git remote get-url origin &>/dev/null; then
        ${pkgs.git}/bin/git push || echo "Push failed, will retry next run"
      else
        echo "No remote configured, skipping push"
      fi
    else
      echo "No changes to commit"
    fi
  '';
in {
  systemd.services.obsidian-git-backup = {
    description = "Git backup for Obsidian vault";
    serviceConfig = {
      Type = "oneshot";
      User = "metamageia";
      WorkingDirectory = "/home/metamageia/Sync/Obsidian";
      ExecStart = "${gitBackupScript}";
      Environment = [
        "HOME=/home/metamageia"
      ];
    };
    path = [pkgs.git pkgs.openssh];
  };

  systemd.timers.obsidian-git-backup = {
    description = "Timer for Obsidian git backup";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
      RandomizedDelaySec = "10min";
    };
  };
}
