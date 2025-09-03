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
    "C /vrising/persistentdata/Settings/ServerHostSettings.json - - - - ${config.sops.templates."ServerHostSettings.json".path}"
  ];

  sops.templates."ServerHostSettings.json".content = ''
    {
      "Name": "crimson-company",
      "Description": "Cracking open some bois with the cold ones",
      "Port": 9876,
      "QueryPort": 9877,
      "MaxConnectedUsers": 40,
      "MaxConnectedAdmins": 4,
      "ServerFps": 30,
      "SaveName": "crimson-company",
      "Password": "${config.sops.placeholder."passwords/vrising"}",
      "Secure": true,
      "ListOnSteam": true,
      "ListOnEOS": true,
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
