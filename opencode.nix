{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  unzip,
}:

let
  version = (builtins.fromJSON (builtins.readFile ./version.json)).version;
  system = stdenv.hostPlatform.system;
  isDarwin = stdenv.hostPlatform.isDarwin;

  # Platform-specific archive format and naming
  platformAttrs = {
    x86_64-linux = {
      arch = "x64";
      ext = "tar.gz";
      hash = "sha256-2RDD7XYTu1eRoyiQRhXUHMJbfTprRw4xmasEJqmVs4o="; # cli-linux-x64
    };
    aarch64-linux = {
      arch = "arm64";
      ext = "tar.gz";
      hash = "sha256-0w0sunRhf057luJVY8lXL/5FP56ucPwN8WKGgTU37nI="; # cli-linux-arm64
    };
    x86_64-darwin = {
      arch = "x64";
      ext = "zip";
      hash = "sha256-QFVZ5Yc6kTH/a8r8QT9G1PGZtEAfIy0AvNMB2X6nzfw="; # cli-darwin-x64
    };
    aarch64-darwin = {
      arch = "arm64";
      ext = "zip";
      hash = "sha256-cvS2AprxhesDCZXPoGLQOJFOMULJqjj3FP5WRI5uh9I="; # cli-darwin-arm64
    };
  };

  attrs = platformAttrs.${system} or (throw "Unsupported system: ${system}");
  os = if isDarwin then "darwin" else "linux";
  url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-${os}-${attrs.arch}.${attrs.ext}";

  # The dynamic linker path for Linux wrapper
  dynamicLinker = lib.optionalString stdenv.hostPlatform.isLinux stdenv.cc.bintools.dynamicLinker;
in

stdenv.mkDerivation {
  pname = "opencode";
  inherit version;

  src = fetchurl {
    inherit url;
    hash = attrs.hash;
  };

  # NOTE: Do NOT use autoPatchelfHook or patchelf on this binary.
  #
  # The opencode CLI is a Bun single-file executable (SFE). Bun SFEs store
  # their bundled JS bytecode appended at the tail of the ELF/Mach-O binary,
  # located via offsets relative to the end of the file. Any tool that modifies
  # binary sections (autoPatchelfHook, patchelf --set-interpreter) will change
  # the binary's size, corrupting the bytecode offset and causing it to fall
  # back to bare Bun CLI help instead of launching OpenCode.
  nativeBuildInputs =
    lib.optional (!isDarwin) makeWrapper
    ++ lib.optional isDarwin unzip;

  dontAutoPatchelf = true;
  dontStrip = true;
  dontFixup = true;

  unpackPhase = ''
    runHook preUnpack
    ${if isDarwin then "unzip $src" else "tar -xzf $src"}
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
  '' + (if isDarwin then ''
    # On Darwin, the binary runs natively — no interpreter patching needed
    mkdir -p $out/bin
    install -Dm755 opencode $out/bin/opencode
  '' else ''
    mkdir -p $out/lib/opencode $out/bin

    # Install the binary untouched — do NOT modify it
    install -Dm755 opencode $out/lib/opencode/opencode

    # Create a wrapper that invokes the binary through the Nix dynamic linker,
    # bypassing the need to patch the ELF interpreter in-place.
    makeWrapper ${dynamicLinker} $out/bin/opencode \
      --add-flags "$out/lib/opencode/opencode"
  '') + ''
    runHook postInstall
  '';

  meta = {
    description = "OpenCode - AI-powered terminal code editor";
    homepage = "https://opencode.ai";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "opencode";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
}
