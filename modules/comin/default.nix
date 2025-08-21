{
  config,
  pkgs,
  inputs,
  userValues,
  ...
}: {
  imports = [
    inputs.comin.nixosModules.comin
  ];

  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = userValues.repoUrl;
        branches.main.name = "main";
      }
    ];
  };
}
