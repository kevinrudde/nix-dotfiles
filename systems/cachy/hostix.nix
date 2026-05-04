{ dotfilesRepoRoot, ... }:

{
  hostix.host = {
    name = "cachy";
    platform = "cachyos";
    arch = "x86_64-linux";
  };

  hostix.packages = {
    pacman = [
      "blueman"
    ];

    aur = [
      "xpadneo-dkms"
      "appimagelauncher"
      "1password"
      "1password-cli"
      "spotify"
      "vicinae-bin"
    ];

    aurHelper = "paru";
  };

  hostix.homeManager = {
    enable = true;
    flakeAttr = "kevin@cachy";
    extraArgs = [ "--impure" ];
  };
}
