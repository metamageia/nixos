{
  config,
  pkgs,
  inputs,
  repoUrl,
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
        url = repoUrl;
        branches.main.name = "main";
      }
    ];
  };
}
