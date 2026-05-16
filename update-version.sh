#!/usr/bin/env bash

set -euo pipefail

REPO="anomalyco/opencode"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

get_hash() {
  local url="$1"
  local temp_file
  temp_file=$(mktemp)

  if curl -sL "$url" -o "$temp_file"; then
    local raw_hash
    raw_hash=$(sha256sum "$temp_file" | cut -d' ' -f1)
    nix hash convert --hash-algo sha256 --to sri "$raw_hash"
  fi
  rm -f "$temp_file"
}

# 1. Get version
if [ -n "${1:-}" ]; then
  version="$1"
  echo "Version provided from argument: $version"
else
  echo "Fetching latest version from GitHub..."
  version=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | \
    grep -oP '"tag_name":\s*"v\K[^"]+')
  
  if [[ -z "$version" ]]; then
    echo "Error: Failed to fetch latest version from GitHub."
    exit 1
  fi
  echo "Latest version: $version"
fi

# Strip leading 'v' if present
version="${version#v}"

echo "------------------------------------------------"
echo "Target Version: $version"
echo "------------------------------------------------"

# 2. Define URLs
url_cli_x64="https://github.com/$REPO/releases/download/v${version}/opencode-linux-x64.tar.gz"
url_cli_arm64="https://github.com/$REPO/releases/download/v${version}/opencode-linux-arm64.tar.gz"
url_desktop_amd64="https://github.com/$REPO/releases/download/v${version}/opencode-desktop-linux-amd64.deb"
url_desktop_arm64="https://github.com/$REPO/releases/download/v${version}/opencode-desktop-linux-arm64.deb"

# 3. Download and compute hashes
echo "Computing hash for opencode CLI (x86_64)..."
hash_cli_x64=$(get_hash "$url_cli_x64")
if [[ -z "$hash_cli_x64" ]]; then
  echo "Error: Failed to download opencode CLI x64."
  exit 1
fi
echo "  Hash: $hash_cli_x64"

echo "Computing hash for opencode CLI (aarch64)..."
hash_cli_arm64=$(get_hash "$url_cli_arm64")
if [[ -z "$hash_cli_arm64" ]]; then
  echo "Warning: Failed to download opencode CLI arm64. Setting hash to placeholder."
  hash_cli_arm64="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
else
  echo "  Hash: $hash_cli_arm64"
fi

echo "Computing hash for opencode-desktop (x86_64)..."
hash_desktop_amd64=$(get_hash "$url_desktop_amd64")
if [[ -z "$hash_desktop_amd64" ]]; then
  echo "Error: Failed to download opencode-desktop amd64."
  exit 1
fi
echo "  Hash: $hash_desktop_amd64"

echo "Computing hash for opencode-desktop (aarch64)..."
hash_desktop_arm64=$(get_hash "$url_desktop_arm64")
if [[ -z "$hash_desktop_arm64" ]]; then
  echo "Warning: Failed to download opencode-desktop arm64. Setting hash to placeholder."
  hash_desktop_arm64="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
else
  echo "  Hash: $hash_desktop_arm64"
fi

# 4. Update version.json
echo "Updating version.json..."
cat > "$SCRIPT_DIR/version.json" << EOF
{
  "version": "$version"
}
EOF

# 5. Update opencode.nix
echo "Updating opencode.nix..."
opencode_file="$SCRIPT_DIR/opencode.nix"
if [[ ! -f "$opencode_file" ]]; then
  echo "Error: $opencode_file not found."
  exit 1
fi

temp_file=$(mktemp)
sed "s|\"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\"; # cli-x64|\"$hash_cli_x64\"; # cli-x64|" "$opencode_file" > "$temp_file"
sed -i "s|\"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\"; # cli-arm64|\"$hash_cli_arm64\"; # cli-arm64|" "$temp_file"
mv "$temp_file" "$opencode_file"

# 6. Update opencode-desktop.nix
echo "Updating opencode-desktop.nix..."
desktop_file="$SCRIPT_DIR/opencode-desktop.nix"
if [[ ! -f "$desktop_file" ]]; then
  echo "Error: $desktop_file not found."
  exit 1
fi

temp_file=$(mktemp)
sed "s|\"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\"; # desktop-amd64|\"$hash_desktop_amd64\"; # desktop-amd64|" "$desktop_file" > "$temp_file"
sed -i "s|\"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\"; # desktop-arm64|\"$hash_desktop_arm64\"; # desktop-arm64|" "$temp_file"
mv "$temp_file" "$desktop_file"

echo "------------------------------------------------"
echo "Success! Updated to version $version"
echo "------------------------------------------------"
echo "  opencode CLI x64:     $hash_cli_x64"
echo "  opencode CLI arm64:   $hash_cli_arm64"
echo "  opencode-desktop amd64: $hash_desktop_amd64"
echo "  opencode-desktop arm64: $hash_desktop_arm64"
echo "------------------------------------------------"
