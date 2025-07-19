{
  description = "Metamageia's personal NixOS flake.";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; 

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    niri-flake.url = "github:sodiboo/niri-flake";
    niri-flake.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:danth/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
    };
    
  outputs = { self, nixpkgs, stylix, home-manager, ... }@inputs:
    let 
      system = "x86_64-linux";
      lib = inputs.nixpkgs.lib;

      pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      };

      wallpaper = ./wallpapers/el-dorgeshi-01.png;
      
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
            inherit wallpaper;
          };
          modules = [ 
            ./hosts/laptop/configuration.nix
            ./modules/core-configuration.nix
            ./modules/apps/home-manager.nix

            # Users
            ./home/users/metamageia/default.nix

            # DE / WM
            inputs.niri-flake.nixosModules.niri
            inputs.stylix.nixosModules.stylix
            ./modules/apps/sddm.nix
            ./modules/apps/niri.nix
            ./modules/apps/stylix.nix


            # Special Modules
            ./modules/musicproduction.nix
            ./modules/development.nix
            ./modules/homeserver.nix
            #./modules/gaming.nix 
          ];
        };
        desktop = lib.nixosSystem {
          inherit system;
          inherit pkgs;  
          specialArgs = {
            hostName = "desktop";
            inherit inputs;  
            inherit system;
            inherit wallpaper;
          };
          modules = [ 
            ./hosts/desktop/configuration.nix
            ./modules/core-configuration.nix
            ./modules/desktop.nix
            
            # Users
            ./metamageia/default.nix
            inputs.niri-flake.nixosModules.niri
            inputs.stylix.nixosModules.stylix

            # Special Modules
            ./modules/musicproduction.nix
            ./modules/development.nix
            ./modules/homeserver.nix
            #./modules/gaming.nix 
          ];
        };  
      };
    };
}
