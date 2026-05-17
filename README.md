# OpenCode Nix Flake

[![OpenCode Version](https://img.shields.io/github/v/release/anomalyco/opencode?label=opencode&color=blue&logo=github)](https://github.com/anomalyco/opencode/releases/latest)
[![Update Status](https://img.shields.io/github/actions/workflow/status/Hy4ri/opencode-flake/update.yml?label=auto-update)](https://github.com/Hy4ri/opencode-flake/actions/workflows/update.yml)

Nix flake for [OpenCode](https://opencode.ai) — an AI-powered terminal code editor and desktop IDE.  
Provides reproducible, declarative packaging of OpenCode for NixOS, Home Manager, and `nix run`.

---

## What is OpenCode?

[OpenCode](https://opencode.ai) is an AI-powered code editor that runs in your terminal (CLI) or as a full desktop application (Electron). It brings AI-assisted development to your fingertips with features like code completion, chat, and multi-file editing — all while keeping your data local and private.

This flake packages both editions:

| Package | Description | Platforms |
|---------|-------------|----------|
| `opencode` | Terminal-based CLI editor | Linux, macOS |
| `opencode-desktop` | Desktop IDE (Electron) | Linux only |

---

## Prerequisites

- **Nix** with [flakes](https://nixos.wiki/wiki/Flakes) enabled
- **Linux** (x86_64, aarch64) or **macOS** (x86_64, Apple Silicon)
- *(Optional)* [NixOS](https://nixos.org/) or [Home Manager](https://github.com/nix-community/home-manager) for declarative installation

---

## Quick Start

Try OpenCode immediately without installing permanently:

```bash
# Run the CLI editor
nix run github:Hy4ri/opencode-flake

# Run the desktop IDE
nix run github:Hy4ri/opencode-flake#opencode-desktop
```

---

## Installation

### 1. Add the Flake Input

In your NixOS configuration or Home Manager flake:

```nix
{
  inputs.opencode.url = "github:Hy4ri/opencode-flake";
}
```

### 2. Choose an Overlay Strategy

#### A) Default overlay (both packages)

Gives you access to both `opencode` and `opencode-desktop` through `pkgs`:

```nix
# NixOS (configuration.nix)
nixpkgs.overlays = [ inputs.opencode.overlays.default ];

# Home Manager
home-manager.users.<user>.nixpkgs.overlays = [ inputs.opencode.overlays.default ];
```

Then install:

```nix
# NixOS
environment.systemPackages = [ pkgs.opencode pkgs.opencode-desktop ];

# Home Manager
home.packages = [ pkgs.opencode pkgs.opencode-desktop ];
```

#### B) Individual overlays (only what you need)

```nix
# Only the CLI
nixpkgs.overlays = [ inputs.opencode.overlays.opencode ];

# Only the desktop IDE
nixpkgs.overlays = [ inputs.opencode.overlays.opencode-desktop ];
```

### 3. Direct Package Reference (Without Overlays)

If you prefer not to use overlays, reference the packages directly:

```nix
{
  inputs.opencode.url = "github:Hy4ri/opencode-flake";

  outputs = { self, nixpkgs, opencode }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [
            opencode.packages.${pkgs.system}.opencode
            opencode.packages.${pkgs.system}.opencode-desktop
          ];
        })
      ];
    };
  };
}
```

---

## Development

### Dev Shell

Enter a development environment with all tools needed for maintenance:

```bash
nix develop github:Hy4ri/opencode-flake
```

### Updating the Version

The version is updated automatically via GitHub Actions daily. To update manually:

```bash
# Update to latest release
./update-version.sh

# Update to a specific version
./update-version.sh 1.16.0
```

The script will download all platform archives, compute SRI hashes, and update `version.json`, `opencode.nix`, and `opencode-desktop.nix`.

### CI Auto-Update

The [update workflow](.github/workflows/update.yml) runs daily at 17:00 UTC and:

1. Checks for a new upstream release
2. Runs `update-version.sh` to fetch and hash all binaries
3. Updates `flake.lock` to the latest nixpkgs
4. Verifies the flake evaluates and the CLI builds
5. Commits and pushes only if verification passes

---

## Contributing

1. Fork the repository
2. Enter the dev shell: `nix develop`
3. Make your changes
4. Verify with `nix flake check` and `nix build .#opencode`
5. Submit a pull request

---

## License

This flake packaging is provided under the **MIT** license.

Note: OpenCode itself may have its own license terms. Refer to the [OpenCode repository](https://github.com/anomalyco/opencode) for details.

