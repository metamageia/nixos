{
  description = "Metamageia's personal NixOS flake.";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; 

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

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
            ./system/macbook/macbook.nix
            ./modules/core-configuration.nix
            inputs.home-manager.nixosModules.home-manager
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.metamageia = ./modules/users/metamageia.nix;
              home-manager.backupFileExtension = "backup";

            }

            # DE / WM
             ./modules/apps/niri.nix
            inputs.stylix.nixosModules.stylix
            ./modules/apps/sddm.nix

            # Special Modules
            ./modules/musicproduction.nix
            ./modules/development.nix
            ./modules/homeserver.nix
            #./stylix.nix
            #./modules/gaming.nix 
          ];
        };
        
        dell = lib.nixosSystem {
          inherit system;
          modules = [ 
            ./system/dell/dell.nix
            ./modules/core-configuration.nix
          ];
          specialArgs = {
            hostName = "dell";
            inherit pkgs;
          };
        };
      };

      # --- User-specific Configurations --- #
      homeConfigurations = {
        metamageia = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./modules/users/metamageia.nix
            ./modules/apps/niri.nix

          ];
        };   
      };
    };
}
