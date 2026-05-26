{ lib
, fetchurl
, rustPlatform
, pkg-config
, makeWrapper
, dbus
, libpulseaudio
, libxkbcommon
, fontconfig
, freetype
, wayland
, libGL
, vulkan-loader
, openssl
, expat
}:

rustPlatform.buildRustPackage rec {
  pname = "librepods";
  version = "0.1.0";

  src = fetchurl {
    url = "https://github.com/kavishdevar/librepods/releases/download/linux-v${version}/librepods-v${version}-source.tar.gz";
    hash = "sha256-eIKNYRPc3De+mqAG16Q37BcFl4ZpzduTQoJOyVRqe04=";
  };

  # Upstream tarball ships its Cargo deps in vendor/ with .cargo/config.toml
  # already wired up; reuse them directly instead of re-vendoring.
  cargoVendorDir = "vendor";

  nativeBuildInputs = [ pkg-config makeWrapper ];

  buildInputs = [
    dbus
    libpulseaudio
    libxkbcommon
    fontconfig
    freetype
    wayland
    libGL
    vulkan-loader
    openssl
    expat
  ];

  postInstall = ''
    install -Dm644 assets/me.kavishdevar.librepods.desktop \
      $out/share/applications/me.kavishdevar.librepods.desktop
    install -Dm644 assets/icon.png \
      $out/share/icons/hicolor/256x256/apps/me.kavishdevar.librepods.png
  '';

  # iced/winit/wgpu dlopen Vulkan, GL, Wayland, and xkbcommon at runtime; on
  # generic-linux home-manager we have to put them on LD_LIBRARY_PATH so the
  # loader finds the /nix/store copies.
  postFixup = ''
    wrapProgram $out/bin/librepods \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          vulkan-loader
          libGL
          wayland
          libxkbcommon
          fontconfig
          freetype
        ]
      }
  '';

  meta = {
    description = "Linux client for AirPods feature parity (battery, ANC, ear detection, ...)";
    homepage = "https://github.com/kavishdevar/librepods";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "librepods";
  };
}
