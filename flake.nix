{
  description = "OpenCode Nix Flake - CLI and Desktop applications";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    nixpkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      });
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
      isLinux = pkgs.stdenv.hostPlatform.isLinux;
    in {
      opencode = pkgs.callPackage ./opencode.nix {};
      default = self.packages.${system}.opencode;
    }
    // pkgs.lib.optionalAttrs isLinux {
      opencode-desktop = pkgs.callPackage ./opencode-desktop.nix {};
    });

    overlays = {
      opencode = final: prev: {
        opencode = final.callPackage ./opencode.nix {};
      };

      opencode-desktop = final: prev: {
        opencode-desktop = final.callPackage ./opencode-desktop.nix {};
      };

      default = final: prev:
        self.overlays.opencode final prev
        // (
          if prev.stdenv.hostPlatform.isLinux
          then self.overlays.opencode-desktop final prev
          else {}
        );
    };
  };
}
