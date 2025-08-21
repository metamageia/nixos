{ pkgs, ... }:

let
  serverPassword = "test";
  rconPassword = "";

  serverSettings = {
    Name = "Crimson Company";
    Description = "";
    Port = 9876;
    QueryPort = 9877;
    MaxConnectedUsers = 40;
    MaxConnectedAdmins = 4;
    ServerFps = 30;
    SaveName = "crimson-company";
    Password = serverPassword;
    Secure = true;
    ListOnSteam = false;
    ListOnEOS = false;
    AutoSaveCount = 20;
    AutoSaveInterval = 120;
    CompressSaveFiles = true;
    GameSettingsPreset = "";
    GameDifficultyPreset = "";
    AdminOnlyDebugEvents = true;
    DisableDebugEvents = false;
    API = { Enabled = false; };
    Rcon = {
      Enabled = false;
      Port = 25575;
      Password = rconPassword;
    };
  };
in {
  systemd.tmpfiles.rules = [
    ''
      f+ /vrising/persistentdata/Settings/ServerGameSettings.json 0644 root root - ${builtins.toJSON serverSettings}
    ''
  ];
}