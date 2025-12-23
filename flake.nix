{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # https://github.com/DeterminateSystems/determinate/releases
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3.15.0";

    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devenv.url = "github:cachix/devenv/v1.11.2";

    sops-nix.url = "github:Mic92/sops-nix";

    mac-app-util.url = "github:hraban/mac-app-util";
  };

  outputs =
    { self
    , nixpkgs
    , determinate
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
      defaultPackage.x86_64-linux = home-manager.defaultPackage.x86_64-linux;
      defaultPackage.aarch64-darwin = home-manager.defaultPackage.aarch64-darwin;
      defaultPackage.x86_64-darwin = home-manager.defaultPackage.x86_64-darwin;

      darwinConfigurations = {
        phobos = nix-darwin.lib.darwinSystem {
          specialArgs = extraArgs // {
            remapKeys = false;
          };
          system = "aarch64-darwin";
          modules = [
            ./systems/phobos
            home-manager.darwinModules.default
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = extraArgs;
            }
            determinate.darwinModules.default
            {
              determinate-nix.customSettings = {
                lazy-trees = true;
                trusted-users = "root kevin";
                trusted-substituters = "https://cachix.cachix.org https://nixpkgs.cachix.org";
                trusted-public-keys = "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM= nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
              };
            }
          ];
        };
      };

      homeConfigurations = {
        # VM running Arch Linux
        "kevin@archlinux-vm" = home-manager.lib.homeManagerConfiguration {
          modules = [ ./home/archlinux-vm.nix ];
          pkgs = import nixpkgs { system = "x86_64-linux"; };
          extraSpecialArgs = extraArgs;
        };

        # WSL2 running Ubuntu
        "kevin@KevinsPC" = home-manager.lib.homeManagerConfiguration {
          modules = [ ./home/kevins-pc.nix ];
          pkgs = import nixpkgs { system = "x86_64-linux"; };
          extraSpecialArgs = extraArgs;
        };

        # Cachy
        "kevin@cachy" = home-manager.lib.homeManagerConfiguration {
          modules = [ ./home/cachy.nix ];
          pkgs = import nixpkgs { system = "x86_64-linux"; };
          extraSpecialArgs = extraArgs;
        };
      };
    };
}
