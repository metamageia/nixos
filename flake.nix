{
  description = "Metamageia's personal NixOS flake.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    alejandra.url = "github:kamadorueda/alejandra/4.0.0";
    alejandra.inputs.nixpkgs.follows = "nixpkgs";

    hermes-agent.url = "github:NousResearch/hermes-agent";

    qml-niri.url = "github:imiric/qml-niri";
    qml-niri.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    infernixos.url = "github:metamageia/infernixos";
    infernixos.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    sops-nix,
    alejandra,
    infernixos,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    lib = inputs.nixpkgs.lib;

    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.permittedInsecurePackages = [
        "broadcom-sta-6.30.223.271-63-6.18.41"
      ];
    };

    userValues = {
      wallpapersDir = ./wallpapers;
      repoUrl = "https://github.com/metamageia/nixos.git";
      publicHost = "arcanum.gagelara.com";
      sopsFile = ./secrets/homelab.secrets.yaml;
      secretsDir = "${self}/secrets";
    };
  in {
    nixosConfigurations = {
      auriga = lib.nixosSystem {
        inherit system;
        inherit pkgs;
        specialArgs = {
          hostName = "auriga";
          nebulaIP = "192.168.100.3";
          inherit inputs;
          inherit userValues;
        };
        modules = [
          ./modules/hosts/auriga
          ./modules/common.nix
        ];
      };
      saiadha = lib.nixosSystem {
        inherit system;
        inherit pkgs;
        specialArgs = {
          hostName = "saiadha";
          nebulaIP = "192.168.100.2";
          inherit inputs;
          inherit userValues;
        };
        modules = [
          ./modules/hosts/saiadha
          ./modules/common.nix
        ];
      };
      setseke = lib.nixosSystem {
        inherit system;
        inherit pkgs;
        specialArgs = {
          hostName = "setseke";
          nebulaIP = "192.168.100.4";
          inherit inputs;
          inherit userValues;
        };
        modules = [
          ./modules/hosts/setseke
          ./modules/common.nix
        ];
      };
      beacon = nixpkgs.lib.nixosSystem {
        inherit system;
        inherit pkgs;
        specialArgs = {
          hostName = "beacon";
          inherit inputs;
          inherit userValues;
          nebulaIP = "192.168.100.1";
        };
        modules = [
          "${nixpkgs}/nixos/modules/virtualisation/digital-ocean-image.nix"
          ./modules/hosts/beacon
          ./modules/common.nix
        ];
      };
    };
    devShells.${system}.default = pkgs.mkShell {
      inherit system;
      buildInputs = [
        pkgs.doctl
        pkgs.openssl
        pkgs.age
        pkgs.sops
        pkgs.dig
      ];

      shellHook = ''
        if [ -f ./secrets/homelab.secrets.env ]; then
          set -a
          eval "$(sops -d ./secrets/homelab.secrets.env)"
          set +a
        fi

        echo "Welcome to the Homeserver development environment!"
      '';
    };
  };
}
