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
      lib = nixpkgs.lib;
      
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      pkgModule = { nixpkgs, ... }: {
        nixpkgs.pkgs = pkgs;
      };

    in {
          
      # --- Host-specific Configurations --- #
      nixosConfigurations = {
        macbook = lib.nixosSystem {
          inherit system;
          specialArgs = {
            hostName = "macbook";
            inherit inputs;
            inherit system;
          };
          modules = [ 
            pkgModule
            ./nixos/hosts/macbook/macbook.nix
            ./nixos/modules/core-configuration.nix
            inputs.home-manager.nixosModules.home-manager
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.metamageia = ./home/users/metamageia/metamageia.nix;
              home-manager.backupFileExtension = "backup";

            }

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

      # --- User-specific Configurations --- #
      homeConfigurations = {
        metamageia = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home.modules/users/metamageia/metamageia.nix
          ];
        };   
      };
    };
}
