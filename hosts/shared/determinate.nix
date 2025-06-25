{ pkgs
, ...
}: {
  environment.etc."nix/nix.custom.conf".text = ''
    lazy-trees = true
    trusted-users = root C.Hessel
    trusted-substituters = https://cachix.cachix.org https://nixpkgs.cachix.org
    trusted-public-keys = cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM= nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
  '';
}
