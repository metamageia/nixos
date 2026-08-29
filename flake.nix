{
  description = "Metamageia's personal NixOS flake.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

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

    compose2nix.url = "github:aksiksi/compose2nix";
    compose2nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-on-droid.url = "github:nix-community/nix-on-droid/release-24.05";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";

    affinity-nix.url = "github:mrshmllow/affinity-nix";

    claude-code.url = "github:sadjow/claude-code-nix";

    # Intentionally not following nixpkgs: the package is built with uv2nix,
    # which resolves Python deps against upstream's locked nixpkgs.
    hermes-agent.url = "github:NousResearch/hermes-agent";

    aagl.url = "github:ezKEa/aagl-gtk-on-nix";
    aagl.inputs.nixpkgs.follows = "nixpkgs";

    # qml-niri: QML plugin exposing niri IPC to QuickShell (used by the
    # QuickShell status bar, modules/quickshell). NOT in nixpkgs — flake input.
    # Its default package installs the plugin to $out/lib/qt-6/qml/Niri/, which
    # modules/quickshell adds to QML2_IMPORT_PATH so `import Niri` resolves.
    qml-niri.url = "github:imiric/qml-niri";
    qml-niri.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    stylix,
    comin,
    home-manager,
    sops-nix,
    alejandra,
    compose2nix,
    nix-on-droid,
    affinity-nix,
    claude-code,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    lib = inputs.nixpkgs.lib;

    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      # setseke's hardware-configuration.nix enables the Broadcom STA wifi driver
      # (boot.kernelModules = [ "wl" ]), which nixpkgs marks insecure (CVE-2019-9501/
      # 9502). The nixpkgs instance is created here (externally), so the permit must
      # live on this import, not in a host module (a module nixpkgs.config throws the
      # "externally created instance" assertion). The version string embeds the kernel
      # (…-6.18.41); keep it in lockstep with the pinned nixpkgs/kernel.
      config.permittedInsecurePackages = [
        "broadcom-sta-6.30.223.271-63-6.18.41"
      ];
    };

    userValues = {
      # Git-tracked wallpaper set; read-only store path at build time, used by the
      # wallust switcher at runtime (modules/wallust). Add a wallpaper => commit + rebuild.
      wallpapersDir = ./wallpapers;
      repoUrl = "https://github.com/metamageia/nixos.git";
      # DNS name for the lighthouse; its A record in Route 53 owns the public IP.
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
    nixOnDroidConfigurations = {
      phone = nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = import nixpkgs {system = "aarch64-linux";};
        specialArgs = {
          hostName = "phone";
          inherit inputs;
          inherit userValues;
          nebulaIP = "192.168.100.4";
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
  };
}
