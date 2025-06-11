{
  
  description = "Metamageia's personal NixOS flake.";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; #defines the git repo for nixpkgs. Choose latest stable

    # Nix User Repository (NUR)
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager 
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Stylix base-16 color & typography manager
    stylix.url = "github:danth/stylix";

    zen-browser.url = "github:MarceColl/zen-browser-flake";

    };
    
  outputs = { self, nixpkgs, stylix, home-manager, ... }@inputs:
    let #declare variables
      
      # Configure system
      system = "x86_64-linux";
      
      # Configure lib
      lib = nixpkgs.lib; #passes lib from nixpkgs input to nixosCOnfigurations
      
      #Configure pkgs
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
        
        # Config for macbook
        macbook = lib.nixosSystem {
          inherit system;
          modules = [ 
            pkgModule
            inputs.home-manager.nixosModules.home-manager
            ./system/macbook/macbook.nix
            ./modules/core-configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.metamageia = ./users/metamageia.nix;

              # Optionally, use home-manager.extraSpecialArgs to pass
              # arguments to home.nix
            }
            #inputs.stylix.nixosModules.stylix
            #./stylix.nix
            #./modules/gaming.nix 
            ./modules/musicproduction.nix
            ./modules/development.nix
            ./modules/homeserver.nix
          ];
          specialArgs = {
            hostName = "macbook";
            inherit inputs;
            #inherit pkgs;
            inherit system;
          };
        };
        
        # Config for Gigabyte
        gigabyte = lib.nixosSystem {
          inherit system;
          modules = [ 
            ./system/gigabyte.nix
            ./modules/core-configuration.nix
            ./modules/gaming.nix
          ];
          specialArgs = {
            hostName = "gigabyte";
            inherit pkgs;
          };
        };
        
        # Config for Dell Desktop
        dell = lib.nixosSystem {
          inherit system;
          modules = [ 
            ./system/dell/dell.nix
            ./modules/core-configuration.nix
            #./modules/gaming.nix 
            ./modules/musicproduction.nix
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
            ./users/metamageia.nix
          ];
        };   

      };
  

    };
}
