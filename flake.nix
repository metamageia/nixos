{
  description = "Metamageia's personal NixOS flake.";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; 

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    niri-flake.url = "github:sodiboo/niri-flake";
    niri-flake.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:danth/stylix";
    #stylix.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:MarceColl/zen-browser-flake";
    #zen-browser.inputs.nixpkgs.follows = "nixpkgs";
    };
    
  outputs = { self, nixpkgs, stylix, home-manager, ... }@inputs:
    let 
      system = "x86_64-linux";
      lib = inputs.nixpkgs.lib;

      pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      };
      
    in {
          
      # --- Host-specific Configurations --- #
      nixosConfigurations = {
        laptop = lib.nixosSystem {
          inherit system;
          inherit pkgs;
          specialArgs = {
            hostName = "laptop";
            inherit inputs;
            inherit system;
          };
          modules = [ 
            ./nixos/hosts/laptop/configuration.nix
            ./nixos/modules/core-configuration.nix
            ./nixos/modules/apps/home-manager.nix

            # Users
            ./home/users/metamageia/default.nix

            # DE / WM
            inputs.niri-flake.nixosModules.niri
            inputs.stylix.nixosModules.stylix
            ./nixos/modules/apps/sddm.nix
            ./nixos/modules/apps/niri.nix


            # Special Modules
            ./nixos/modules/musicproduction.nix
            ./nixos/modules/development.nix
            ./nixos/modules/homeserver.nix
            #./nixos/modules/gaming.nix 
          ];
        };
      };
    };
}
