{pkgs, ...}: let
  serverPassword = "";
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
    AutoSaveInterval = 300;
    CompressSaveFiles = false;
    GameSettingsPreset = "";
    GameDifficultyPreset = "";
    AdminOnlyDebugEvents = true;
    DisableDebugEvents = false;
    API = {Enabled = false;};
    Rcon = {
      Enabled = false;
      Port = 25575;
      Password = rconPassword;
    };
  };
in {
  environment.etc."vrising/persistentdata/Settings/ServerHostSettings.json".source =
    pkgs.writeText "ServerHostSettings.json"
    (builtins.toJSON serverSettings);
  fileSystems."/vrising/persistentdata/Settings/ServerHostSettings.json" = {
    device = "/etc/vrising/persistentdata/Settings/ServerHostSettings.json";
    options = ["bind"];
  };
}
