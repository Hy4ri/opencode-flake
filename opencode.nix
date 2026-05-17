{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  glibc,
}:

let
  version = (builtins.fromJSON (builtins.readFile ./version.json)).version;

  archMap = {
    x86_64-linux = "x64";
    aarch64-linux = "arm64";
  };

  hashMap = {
    x86_64-linux = "sha256-+K6GeMm8zbr5l3fzb/LV7+aJ1HM4Ty6UuE1s2iVtJUA="; # cli-x64
    aarch64-linux = "sha256-Tyo+MEDG3GcXlhsQNOeuZRlAxEkGXTFsbG4XpLeCk9o="; # cli-arm64
  };

  system = stdenv.hostPlatform.system;
  arch = archMap.${system} or (throw "Unsupported system: ${system}");
  hash = hashMap.${system} or (throw "Unsupported system: ${system}");

  # Resolve the dynamic linker path for the current platform
  dynamicLinker = stdenv.cc.bintools.dynamicLinker;
in

stdenv.mkDerivation rec {
  pname = "opencode";
  inherit version;

  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-${arch}.tar.gz";
    inherit hash;
  };

  # NOTE: Do NOT use autoPatchelfHook or patchelf on this binary.
  #
  # The opencode CLI is a Bun single-file executable (SFE). Bun SFEs store
  # their bundled JS bytecode appended at the tail of the ELF binary, located
  # via offsets relative to the end of the file. Any tool that modifies ELF
  # sections (autoPatchelfHook, patchelf --set-interpreter) will change the
  # binary's size, corrupting the bytecode offset and causing the binary to
  # fall back to bare Bun CLI help instead of launching OpenCode.
  #
  # Instead, we leave the binary untouched and invoke it through the Nix glibc
  # dynamic linker directly via a wrapper.
  nativeBuildInputs = [ makeWrapper ];
  dontAutoPatchelf = true;
  dontStrip = true;
  dontFixup = true;

  unpackPhase = ''
    runHook preUnpack
    tar -xzf $src
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/opencode $out/bin

    # Install the binary untouched — do NOT modify it
    install -Dm755 opencode $out/lib/opencode/opencode

    # Create a wrapper that invokes the binary through the Nix dynamic linker,
    # bypassing the need to patch the ELF interpreter in-place.
    makeWrapper ${dynamicLinker} $out/bin/opencode \
      --add-flags "$out/lib/opencode/opencode"
    runHook postInstall
  '';

  meta = {
    description = "OpenCode - AI-powered terminal code editor";
    homepage = "https://opencode.ai";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "opencode";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
