{ pkgs, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
  nixgl = inputs.nixgl.packages.${system};
  unwrapped = pkgs.callPackage ./package.nix { };
in
{
  # LibrePods uses wgpu/iced. On generic-linux home-manager the bundled Nix
  # vulkan-loader/libEGL can't find the system Mesa ICDs (Asahi GPU driver
  # lives under /usr/lib*/dri and /usr/share/vulkan/icd.d). Layer
  # nixVulkanIntel → nixGLIntel to fix both fail paths (the "Intel" names are
  # historical — these wrappers handle any Mesa-driven GPU, including Asahi).
  home.packages = [
    (pkgs.symlinkJoin {
      name = "librepods-nixgl-${unwrapped.version}";
      paths = [ unwrapped ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        rm -f $out/bin/librepods
        makeWrapper ${nixgl.nixVulkanIntel}/bin/nixVulkanIntel $out/bin/librepods \
          --argv0 librepods \
          --add-flags ${nixgl.nixGLIntel}/bin/nixGLIntel \
          --add-flags ${unwrapped}/bin/librepods
      '';
    })
  ];
}
