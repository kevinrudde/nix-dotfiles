{
  description = "Home Manager configuration";

  inputs = {
    nix.url = "https://flakehub.com/f/DeterminateSystems/nix/2.0";

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devenv.url = "github:cachix/devenv/v1.6.1";

    sops-nix.url = "github:Mic92/sops-nix";

    mac-app-util.url = "github:hraban/mac-app-util";
  };

  outputs =
    { self
    , nix
    , nixpkgs
    , nix-darwin
    , home-manager
    , devenv
    , sops-nix
    , ...
    }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      extraArgs = {
        inherit sops-nix;
        flake = self;
      };
    in
    {
      # macOS configurations
      darwinConfigurations = {
        zoidberg = nix-darwin.lib.darwinSystem {
          specialArgs = extraArgs // {
            remapKeys = false;
          };
          system = "aarch64-darwin";
          modules = [
            ./hosts/zoidberg
            home-manager.darwinModules.default
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = extraArgs;
            }
            nix.darwinModules.default
          ];
        };
      };

      # NixOS configurations (for future Linux support)
      # nixosConfigurations = {
      #   # Example Linux configuration
      #   linux-example = nixpkgs.lib.nixosSystem {
      #     system = "x86_64-linux";
      #     specialArgs = extraArgs;
      #     modules = [
      #       ./hosts/example-linux
      #       home-manager.nixosModules.default
      #       {
      #         home-manager.useGlobalPkgs = true;
      #         home-manager.useUserPackages = true;
      #         home-manager.extraSpecialArgs = extraArgs;
      #         home-manager.users."C.Hessel" = {
      #           imports = [ ./home ];
      #         };
      #       }
      #     ];
      #   };
      # };

      # Standalone home-manager configurations
      homeConfigurations = {
        "C.Hessel" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          extraSpecialArgs = extraArgs;
          modules = [
            ./home
          ];
        };
      };
    };
}
