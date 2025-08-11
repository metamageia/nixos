{
  description = "Metamageia's personal NixOS flake.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    niri-flake.url = "github:sodiboo/niri-flake";
    niri-flake.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:danth/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    homelab.url = "github:metamageia/homelab";
    homelab.inputs.nixpkgs.follows = "nixpkgs";

    alejandra.url = "github:kamadorueda/alejandra/4.0.0";
    alejandra.inputs.nixpkgs.follows = "nixpkgs";

    attic.url = "github:zhaofengli/attic";
    attic.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    stylix,
    home-manager,
    homelab,
    sops-nix,
    alejandra,
    attic,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    lib = inputs.nixpkgs.lib;

    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    sopsFile = ./secrets/homelab.secrets.yaml;

    wallpaper = ./wallpapers/el-roving-clans-01.jpg;
  in {
    nixosConfigurations = {
      argosy = lib.nixosSystem {
        inherit system;
        inherit pkgs;
        specialArgs = {
          hostName = "argosy";
          inherit inputs;
          inherit system;
          inherit wallpaper;
          inherit sopsFile;
        };
        modules = [
          ./hosts/argosy/configuration.nix
        ];
      };
      auriga = lib.nixosSystem {
        inherit system;
        inherit pkgs;
        specialArgs = {
          hostName = "auriga";
          inherit inputs;
          inherit system;
          inherit wallpaper;
          inherit sopsFile;
        };
        modules = [
          ./hosts/auriga/configuration.nix
        ];
      };
      saiadha = lib.nixosSystem {
        inherit system;
        inherit pkgs;
        specialArgs = {
          hostName = "saiadha";
          inherit inputs;
          inherit system;
          inherit wallpaper;
          inherit sopsFile;
        };
        modules = [
          ./hosts/saiadha/configuration.nix
        ];
      };
    };
  };
}
