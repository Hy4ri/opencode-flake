{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libGL,
  libgbm,
  libX11,
  libXcomposite,
  libXcursor,
  libXdamage,
  libXext,
  libXfixes,
  libXi,
  libxkbcommon,
  libXrandr,
  libXrender,
  libXScrnSaver,
  libXtst,
  libxcb,
  libuuid,
  libxml2,
  nspr,
  nss,
  pango,
  pipewire,
  systemd,
  wayland,
  vulkan-loader,
  libpulseaudio,
  libkrb5,
  xdg-utils,
}:

let
  version = (builtins.fromJSON (builtins.readFile ./version.json)).version;

  archMap = {
    x86_64-linux = "amd64";
    aarch64-linux = "arm64";
  };

  hashMap = {
    x86_64-linux = "sha256-M080yE4Yd8tSjjL5nBzPczO1wln0t36wFAynjmu0ZQE="; # desktop-amd64
    aarch64-linux = "sha256-yTfx8CwRtw+XfdvWxW3KFCkQg0Rvr4o+YVW6uzKlpIo="; # desktop-arm64
  };

  system = stdenv.hostPlatform.system;
  arch = archMap.${system} or (throw "Unsupported system: ${system}");
  hash = hashMap.${system} or (throw "Unsupported system: ${system}");
in

stdenv.mkDerivation rec {
  pname = "opencode-desktop";
  inherit version;

  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-desktop-linux-${arch}.deb";
    inherit hash;
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libGL
    libgbm
    libX11
    libXcomposite
    libXcursor
    libXdamage
    libXext
    libXfixes
    libXi
    libxkbcommon
    libXrandr
    libXrender
    libXScrnSaver
    libXtst
    libxcb
    libuuid
    libxml2
    nspr
    nss
    pango
    pipewire
    systemd
    wayland
    vulkan-loader
    libpulseaudio
    libkrb5
    stdenv.cc.cc
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/opencode-desktop
    cp -r opt/opencode-desktop/* $out/opt/opencode-desktop/

    mkdir -p $out/share
    cp -r usr/share/* $out/share/ 2>/dev/null || true

    substituteInPlace $out/share/applications/*.desktop \
      --replace-fail /usr/bin/opencode-desktop $out/bin/opencode-desktop

    for d in 16 24 32 48 64 128 256 512; do
      if [ -f "$out/opt/opencode-desktop/product_logo_''${d}.png" ]; then
        mkdir -p "$out/share/icons/hicolor/''${d}x''${d}/apps"
        ln -s "$out/opt/opencode-desktop/product_logo_''${d}.png" \
          "$out/share/icons/hicolor/''${d}x''${d}/apps/opencode-desktop.png"
      fi
    done

    mkdir -p $out/bin
    makeWrapper $out/opt/opencode-desktop/opencode-desktop $out/bin/opencode-desktop \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs} \
      --set PATH ${lib.makeBinPath [ xdg-utils ]}

    runHook postInstall
  '';

  meta = {
    description = "OpenCode Desktop - AI-powered IDE";
    homepage = "https://opencode.ai";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "opencode-desktop";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
