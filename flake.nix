{
  
  description = "Metamageia's personal NixOS flake.";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11"; #defines the git repo for nixpkgs. Choose latest stable

    # Home Manager 
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Stylix base-16 color & typography manager
    stylix.url = "github:danth/stylix";

    # Anime game launcher pkgs
    aagl.url = "github:ezKEa/aagl-gtk-on-nix";
    aagl.inputs.nixpkgs.follows = "nixpkgs"; # Name of nixpkgs input you want to use

    };
    
  outputs = { self, nixpkgs, aagl, stylix, home-manager, ... }@inputs:
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
          permittedInsecurePackages = [
            "electron-25.9.0"
          ];
        };
      };
    
    in {
          
      # --- Host-specific Configurations --- #
      nixosConfigurations = {
        
        # Config for macbook
        macbook = lib.nixosSystem {
          inherit system;
          modules = [ 
            inputs.home-manager.nixosModules.home-manager
            ./system/macbook/macbook.nix
            ./modules/core-configuration.nix
            #./system/bootloaders/grub.nix
            #inputs.stylix.nixosModules.stylix
            #./stylix.nix
            ./modules/gaming.nix 
            ./modules/musicproduction.nix
            ./modules/development.nix
            ./modules/homeserver.nix
          ];
          specialArgs = {
            hostName = "macbook";
            inherit inputs;
            inherit pkgs;
            inherit aagl;
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
            inherit aagl;
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
            inherit aagl;
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
