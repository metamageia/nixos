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

    alejandra.url = "github:kamadorueda/alejandra/4.0.0";
    alejandra.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    stylix,
    home-manager,
    sops-nix,
    alejandra,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    lib = inputs.nixpkgs.lib;

    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    repoUrl = "https://github.com/metamageia/nixos-personal.git";
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
          ./modules/hosts/argosy
          ./modules/common.nix
          ./modules/desktop.nix
          ./modules/homelab.nix
        ];
      };
      auriga = lib.nixosSystem {
        inherit system;
        inherit pkgs;
        specialArgs = {
          hostName = "auriga";
          nebulaIP = "192.168.100.3";
          inherit inputs;
          inherit system;
          inherit wallpaper;
          inherit sopsFile;
        };
        modules = [
          ./modules/hosts/auriga
          ./modules/common.nix
          ./modules/desktop.nix
          ./modules/homelab.nix
        ];
      };
      saiadha = lib.nixosSystem {
        inherit system;
        inherit pkgs;
        specialArgs = {
          hostName = "saiadha";
          nebulaIP = "192.168.100.2";
          inherit inputs;
          inherit system;
          inherit wallpaper;
          inherit sopsFile;
        };
        modules = [
          ./modules/hosts/saiadha
          ./modules/common.nix
          ./modules/desktop.nix
          ./modules/homelab.nix
        ];
      };
      droplet = nixpkgs.lib.nixosSystem {
        inherit system;
        inherit pkgs;
        specialArgs = {
          hostName = "droplet";
          inherit inputs;
          inherit system;
          inherit sopsFile;
          inherit repoUrl;
          nebulaIP = "192.168.100.1";
        };
        modules = [
          ./modules/hosts/droplet
          ./modules/common.nix
          ./modules/homelab.nix
        ];
      };
    };
    devShells.${system}.default = pkgs.mkShell {
      inherit system;
      buildInputs = [pkgs.terraform pkgs.doctl pkgs.kustomize pkgs.openssl pkgs.age];
      shellHook = ''
        echo "Welcome to the Homeserver development environment!"
        set -a
        source ./secrets/.env
        set +a
      '';
    };
  };
}
