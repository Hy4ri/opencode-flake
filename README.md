# OpenCode Nix Flake

[![OpenCode Version](https://img.shields.io/github/v/release/anomalyco/opencode?label=opencode&color=blue&logo=github)](https://github.com/anomalyco/opencode/releases/latest)
[![Update Status](https://img.shields.io/github/actions/workflow/status/Hy4ri/opencode-flake/update.yml?label=auto-update)](https://github.com/Hy4ri/opencode-flake/actions/workflows/update.yml)

Run and install [OpenCode](https://opencode.ai) on NixOS, Home Manager, nix-darwin, or any system with Nix.

OpenCode is an AI coding agent. It runs in your terminal (CLI) or as a desktop app.

The flake is updated automatically every day.

## Packages

| Package | What it is | Command | Platforms |
|---|---|---|---|
| `opencode` (default) | Terminal app (CLI) | `opencode` | Linux, macOS |
| `opencode-desktop` | Desktop app (Electron) | `opencode-desktop` | Linux only |

Linux: `x86_64` and `aarch64`. macOS: Intel and Apple Silicon.

## Try it without installing

You need Nix with [flakes enabled](https://wiki.nixos.org/wiki/Flakes).

```bash
nix run github:Hy4ri/opencode-flake                    # CLI
nix run github:Hy4ri/opencode-flake#opencode-desktop   # desktop app
```

## Install

There are **two ways** to install. **Pick one.** They give the same result.

| Option | Use it when |
|---|---|
| **A. Overlay** | You want to write `pkgs.opencode`, like any other nixpkgs package. |
| **B. Direct package** | You do not want to use overlays. |

### Step 1: Add the flake input (needed for both options)

In your system `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    opencode.url = "github:Hy4ri/opencode-flake";
  };

  outputs = { nixpkgs, ... }@inputs: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; }; # lets your modules use `inputs`
      modules = [ ./configuration.nix ];
    };
  };
}
```

> Already have a flake? Add only the `opencode.url` line, and make sure `inputs` reaches your modules (`specialArgs` for NixOS and nix-darwin, `extraSpecialArgs` for Home Manager).

### Step 2, Option A: Overlay

In `configuration.nix`:

```nix
{ inputs, pkgs, ... }:
{
  nixpkgs.overlays = [ inputs.opencode.overlays.default ];

  environment.systemPackages = [
    pkgs.opencode
    pkgs.opencode-desktop # Linux only
  ];
}
```

For Home Manager, keep the overlay line and use `home.packages = [ pkgs.opencode ];` instead.

Want only one app in `pkgs`? Use `overlays.opencode` or `overlays.opencode-desktop` instead of `overlays.default`.

### Step 2, Option B: Direct package

In `configuration.nix`:

```nix
{ inputs, pkgs, ... }:
let
  opencode = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  environment.systemPackages = [
    opencode.opencode
    opencode.opencode-desktop # Linux only
  ];
}
```

For Home Manager, put the same packages in `home.packages`.

### Step 3: Rebuild

```bash
sudo nixos-rebuild switch --flake .#myhost
```

## Updates

A GitHub Action checks for new OpenCode releases every day at 17:00 UTC, tests the build, and commits the new version. To get it, update your lock file:

```bash
nix flake update opencode
```

### Manual update (maintainers)

```bash
nix develop                     # shell with the update tools
./update-version.sh             # latest release
./update-version.sh 1.16.0      # a specific version
```

The script downloads every platform archive, computes the hashes, and updates `version.json`, `opencode.nix`, and `opencode-desktop.nix`.

## Contributing

1. Fork the repository.
2. Enter the dev shell: `nix develop`.
3. Make your changes.
4. Check them: `nix flake check` and `nix build .#opencode`.
5. Open a pull request.

## License

This flake packaging is provided under the MIT license. OpenCode itself has its own license terms. Refer to the [OpenCode repository](https://github.com/anomalyco/opencode) for details.

## Support

If this flake helps you, you can support my work on [GitHub Sponsors](https://github.com/sponsors/hy4ri) or [Ko-fi](https://ko-fi.com/m_5_7). A star on the repo also helps.
