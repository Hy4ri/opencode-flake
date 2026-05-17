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

> **Note:** Replace `Hy4ri` with the GitHub username or organization that hosts this flake. If you've forked this repository, use your own username.

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

## Verifying the Installation

After installation, confirm everything works:

```bash
# CLI version
opencode --version

# Desktop version
opencode-desktop --version

# If using nix run
nix run github:Hy4ri/opencode-flake -- --version
```

Expected output: `opencode <version>` (check the [latest release](https://github.com/anomalyco/opencode/releases/latest) for the current version).

---

## Updating

### Automatic Updates (CI)

This flake includes a **GitHub Actions workflow** that checks for new OpenCode releases every day at 17:00 UTC. When a new version is detected, it:

1. Fetches the latest release from the [anomalyco/opencode](https://github.com/anomalyco/opencode) repository
2. Downloads the binary archives and computes their SHA-256 hashes
3. Updates `version.json`, `opencode.nix`, and `opencode-desktop.nix`
4. Commits and pushes the changes automatically

The workflow also supports **manual triggering** from the GitHub Actions tab.

### Manual Update

To update the flake to the latest OpenCode release from your local machine:

```bash
# Update to the latest version
./update-version.sh

# Update to a specific version
./update-version.sh <version>
```

The script will:
1. Determine the target version (latest from GitHub or the one you specify)
2. Download both CLI and desktop binaries for all supported architectures
3. Compute SRI-format hashes for each binary
4. Update `version.json` and the hash placeholders in `opencode.nix` and `opencode-desktop.nix`

After running the script, commit the changes:

```bash
git add version.json opencode.nix opencode-desktop.nix
git commit -m "chore: update opencode to <version>"
```

---

## Project Structure

```
.
├── flake.nix               # Flake entry point: packages, overlays, outputs
├── opencode.nix            # Package derivation for the CLI editor
├── opencode-desktop.nix    # Package derivation for the desktop IDE
├── version.json            # Current OpenCode version
├── update-version.sh       # Script to fetch new releases and update hashes
├── .github/
│   └── workflows/
│       └── update.yml      # GitHub Actions: daily auto-update workflow
├── .gitignore              # Ignored files (result/ symlinks, editor artifacts)
└── README.md
```

### Key Files Explained

| File | Purpose |
|------|---------|
| `flake.nix` | Defines the flake's inputs (nixpkgs unstable), supported systems (x86_64, aarch64 Linux), packages, and overlays. Sets `allowUnfree = true` since OpenCode binaries may have non-free dependencies. |
| `opencode.nix` | Derivation that downloads the CLI tarball, runs `autoPatchelfHook` for shared library linking, and installs the `opencode` binary to `$out/bin`. |
| `opencode-desktop.nix` | Derivation that extracts the `.deb` package, wraps the Electron binary with all required library paths (Alsa, CUPS, GL, Wayland, X11, etc.), sets up desktop icons, and creates the `opencode-desktop` launcher. |
| `version.json` | Single source of truth for the current OpenCode version. Both derivations read from this file. |
| `update-version.sh` | Automation script that fetches release metadata, downloads binaries, computes SRI hashes, and wires everything into the Nix expressions. |

---

## Troubleshooting

### "Unsupported system" error

The CLI (`opencode`) supports **x86_64-linux**, **aarch64-linux**, **x86_64-darwin**, and **aarch64-darwin**. The desktop app (`opencode-desktop`) is **Linux-only**. If you're on an unsupported architecture, OpenCode does not currently provide prebuilt binaries for that platform.

### Hash mismatch during build

If you see a hash mismatch error, the version in `version.json` may be stale or the upstream binary may have changed. Run `./update-version.sh` to refresh the hashes.

### `autoPatchelfHook` warnings

Some non-critical shared library warnings may appear during the build. These are typically harmless — the desktop derivation includes a comprehensive set of `buildInputs` covering all known Electron dependencies (Alsa, CUPS, DBus, GL, GTK3, pipewire, Wayland, X11, etc.).

### Desktop app won't launch

Ensure the required system libraries are available. The nix derivation wraps the binary with `LD_LIBRARY_PATH` pointing to all dependencies, but if you're running outside of the Nix environment, you may need additional system packages:

- For **Wayland**: `wayland`, `libxkbcommon`
- For **X11**: `libX11`, `libXcomposite`, `libXcursor`, `libXrandr`, etc.
- For **audio**: `alsa-lib`, `libpulseaudio`
- For **graphics**: `libGL`, `vulkan-loader`

### `nix run` doesn't find the package

Ensure you're using the correct attribute path:

```bash
# Default (CLI)
nix run github:Hy4ri/opencode-flake

# Desktop
nix run github:Hy4ri/opencode-flake#opencode-desktop
```

If the flake is local:
```bash
nix run .#opencode
nix run .#opencode-desktop
```

---

## License

This flake packaging is provided under the **MIT** license.

Note: OpenCode itself may have its own license terms. Refer to the [OpenCode repository](https://github.com/anomalyco/opencode) for details.

---

## Contributing

Contributions are welcome! If you find a bug or have a feature request, please open an issue or pull request.

When contributing:
- Update `version.json` when bumping the OpenCode version
- Update hashes in the `.nix` files if dependencies change
- Follow the existing Nix expression style (use `callPackage`, `lib` patterns, etc.)
- Keep the README in sync with any structural changes
