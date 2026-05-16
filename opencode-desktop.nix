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

    mkdir -p $out/opt

    # Discover actual directory name under opt/
    if [ -d "opt/opencode-desktop" ]; then
      cp -r opt/opencode-desktop $out/opt/
    elif [ -d "opt/opencode" ]; then
      cp -r opt/opencode $out/opt/opencode-desktop
    elif [ -d "opt" ] && [ "$(ls -1 opt/ | wc -l)" -eq 1 ]; then
      # Single directory under opt/ — use it
      cp -r "opt/$(ls -1 opt/ | head -n1)" $out/opt/opencode-desktop
    else
      echo "ERROR: Could not find application directory under opt/"
      echo "Contents of opt/:"
      ls -la opt/ 2>/dev/null || echo "No opt/ directory found"
      echo "Root directory contents:"
      ls -la
      exit 1
    fi

    # Copy usr/share/ if it exists
    if [ -d "usr/share" ]; then
      mkdir -p $out/share
      cp -r usr/share/* $out/share/ 2>/dev/null || true
    fi

    # Fix desktop file paths
    if [ -d "$out/share/applications" ]; then
      for desktop in $out/share/applications/*.desktop; do
        [ -f "$desktop" ] && substituteInPlace "$desktop" \
          --replace-fail /usr/bin/opencode-desktop $out/bin/opencode-desktop \
          --replace-fail /usr/share/opencode-desktop $out/opt/opencode-desktop \
          2>/dev/null || true
      done
    fi

    # Link icons if they exist
    for d in 16 24 32 48 64 128 256 512; do
      if [ -f "$out/opt/opencode-desktop/product_logo_''${d}.png" ]; then
        mkdir -p "$out/share/icons/hicolor/''${d}x''${d}/apps"
        ln -sf "$out/opt/opencode-desktop/product_logo_''${d}.png" \
          "$out/share/icons/hicolor/''${d}x''${d}/apps/opencode-desktop.png"
      fi
    done

    # Find and wrap the binary
    mkdir -p $out/bin
    if [ -f "$out/opt/opencode-desktop/opencode-desktop" ]; then
      makeWrapper $out/opt/opencode-desktop/opencode-desktop $out/bin/opencode-desktop \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs} \
        --set PATH ${lib.makeBinPath [ xdg-utils ]}
    else
      # Try to find the binary
      BINARY=$(find $out/opt/opencode-desktop -maxdepth 2 -name "opencode-desktop" -type f -executable | head -n1)
      if [ -n "$BINARY" ]; then
        makeWrapper "$BINARY" $out/bin/opencode-desktop \
          --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs} \
          --set PATH ${lib.makeBinPath [ xdg-utils ]}
      else
        echo "ERROR: Could not find opencode-desktop binary"
        echo "Contents of $out/opt/opencode-desktop:"
        find $out/opt/opencode-desktop -maxdepth 3 | head -50
        exit 1
      fi
    fi

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
