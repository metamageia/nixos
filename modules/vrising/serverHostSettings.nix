{
  pkgs,
  config,
  userValues,
  ...
}: {
  sops.secrets = {
    "passwords/vrising" = {
      sopsFile = userValues.sopsFile;
    };
  };
  systemd.tmpfiles.rules = [
    "d /vrising/persistentdata/Settings 0755 root root - -"
    "C /vrising/persistentdata/Settings/ServerHostSettings.json 0644 root root - ${config.sops.templates."ServerHostSettings.json".path}"
  ];

  sops.templates."ServerHostSettings.json".content = ''
        {
      "Name": "Crimson Legion",
      "Description": "Cracking open some bois with the cold ones",
      "Port": 9876,
      "QueryPort": 9877,
      "MaxConnectedUsers": 40,
      "MaxConnectedAdmins": 4,
      "ServerFps": 30,
      "SaveName": "Crimson Legion",
      "Password": "${config.sops.placeholder."passwords/vrising"}",
      "Secure": true,
      "ListOnSteam": false,
      "ListOnEOS": false,
      "AutoSaveCount": 20,
      "AutoSaveInterval": 120,
      "CompressSaveFiles": true,
      "GameSettingsPreset": "",
      "GameDifficultyPreset": "",
      "AdminOnlyDebugEvents": true,
      "DisableDebugEvents": false,
      "API": {
        "Enabled": false
      },
      "Rcon": {
        "Enabled": false,
        "Port": 25575,
        "Password": ""
      }
    }
  '';
}
