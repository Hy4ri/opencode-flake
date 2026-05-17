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

  runtimeLibs = [
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
in

stdenv.mkDerivation {
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

  # The musl prebuilts ship libc.musl-*.so.1 SONAMEs that autoPatchelfHook can't
  # resolve on glibc systems. They aren't loaded at runtime on the host libc anyway.
  autoPatchelfIgnoreMissingDeps = [ "libc.musl-*.so.*" ];

  buildInputs = runtimeLibs;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    # The .deb extracts to opt/OpenCode/ with binary named @opencode-aidesktop
    mkdir -p $out/opt/opencode-desktop
    cp -r opt/OpenCode/* $out/opt/opencode-desktop/

    # Copy shared assets if present
    if [ -d usr/share ]; then
      mkdir -p $out/share
      cp -r usr/share/* $out/share/
    fi

    # Fix desktop file paths (Exec and Icon)
    if [ -d "$out/share/applications" ]; then
      for desktop in $out/share/applications/*.desktop; do
        [ -f "$desktop" ] && substituteInPlace "$desktop" \
          --replace-fail /opt/OpenCode/@opencode-aidesktop $out/bin/opencode-desktop \
          --replace-warn /opt/OpenCode/ $out/opt/opencode-desktop/
      done
    fi

    # Wrap the binary
    mkdir -p $out/bin
    makeWrapper $out/opt/opencode-desktop/@opencode-aidesktop $out/bin/opencode-desktop \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs} \
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]}

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
