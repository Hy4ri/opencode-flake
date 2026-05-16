{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  openssl,
  zlib,
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
in

stdenv.mkDerivation {
  pname = "opencode";
  inherit version;

  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-${arch}.tar.gz";
    inherit hash;
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ openssl zlib glibc ];

  unpackPhase = ''
    runHook preUnpack
    tar -xzf $src
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -Dm755 opencode $out/bin/opencode
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
