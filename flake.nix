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
    in {
      opencode = pkgs.callPackage ./opencode.nix {};
      opencode-desktop = pkgs.callPackage ./opencode-desktop.nix {};
      default = self.packages.${system}.opencode;
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
        // self.overlays.opencode-desktop final prev;
    };
  };
}
