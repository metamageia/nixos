{
  description = "Metamageia's personal NixOS flake.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    niri-flake.url = "github:sodiboo/niri-flake";
    niri-flake.inputs.nixpkgs.follows = "nixpkgs";

    comin.url = "github:nlewo/comin";
    comin.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:danth/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    alejandra.url = "github:kamadorueda/alejandra/4.0.0";
    alejandra.inputs.nixpkgs.follows = "nixpkgs";

    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

    compose2nix.url = "github:aksiksi/compose2nix";
    compose2nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-on-droid.url = "github:nix-community/nix-on-droid/release-24.05";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    stylix,
    comin,
    home-manager,
    sops-nix,
    alejandra,
    nixos-generators,
    compose2nix,
    nix-on-droid,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    lib = inputs.nixpkgs.lib;

    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    userValues = {
      wallpaper = ./wallpapers/vrising-02.jpg;
      repoUrl = "https://github.com/metamageia/nixos.git";
      sopsFile = ./secrets/homelab.secrets.yaml;
    };
  in {
    nixosConfigurations = {
      argosy = lib.nixosSystem {
        inherit system;
        inherit pkgs;
        specialArgs = {
          hostName = "argosy";
          inherit inputs;
          inherit system;
          inherit userValues;
        };
        modules = [
          ./modules/hosts/argosy
          ./modules/common.nix
          ./modules/desktop.nix
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
          inherit userValues;
        };
        modules = [
          ./modules/hosts/auriga
          ./modules/common.nix
          ./modules/desktop.nix
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
          inherit userValues;
        };
        modules = [
          ./modules/hosts/saiadha
          ./modules/common.nix
          ./modules/desktop.nix
        ];
      };
      beacon = nixpkgs.lib.nixosSystem {
        inherit system;
        inherit pkgs;
        specialArgs = {
          hostName = "beacon";
          inherit inputs;
          inherit system;
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
    nixOnDroidConfigurations = {
      phone = nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = import nixpkgs {system = "aarch64-linux";};
        specialArgs = {
          hostName = "phone";
          inherit inputs;
          inherit system;
          inherit userValues;
        };
        modules = [./modules/hosts/phone];
      };
    };
    devShells.${system}.default = pkgs.mkShell {
      inherit system;
      buildInputs = [
        pkgs.terraform
        pkgs.doctl
        pkgs.kustomize
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
    packages.x86_64-linux = {
      do = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        specialArgs = {
          hostName = "beacon";
          inherit inputs;
          inherit system;
          inherit userValues;
        };
        modules = [
          ./modules/hosts/digitalocean
        ];
        format = "do";
      };
    };
  };
}
