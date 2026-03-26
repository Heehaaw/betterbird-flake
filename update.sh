#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
metadata_file="$repo_root/metadata.json"

downloads_page="$(curl -fsSL 'https://www.betterbird.eu/downloads/')"
version="$((printf '%s\n' "$downloads_page" \
  | grep -oE 'Current version: Betterbird [^ <]+' \
  | awk '{ print $4 }' \
  | head -n1))"

if [ -z "$version" ]; then
  echo "Unable to determine Betterbird version from downloads page" >&2
  exit 1
fi

major="${version%%.*}"
checksums="$(curl -fsSL "https://www.betterbird.eu/downloads/sha256-${major}.txt")"

arm_hex="$((printf '%s\n' "$checksums" \
  | awk -v version="$version" '$2 == "*betterbird-" version ".en-US.mac-arm64.dmg" { print $1; exit }'))"
x86_hex="$((printf '%s\n' "$checksums" \
  | awk -v version="$version" '$2 == "*betterbird-" version ".en-US.mac.dmg" { print $1; exit }'))"

if [ -z "$arm_hex" ] || [ -z "$x86_hex" ]; then
  echo "Unable to find macOS checksum entries for Betterbird $version" >&2
  exit 1
fi

arm_hash="$(nix hash convert --to sri "sha256:$arm_hex")"
x86_hash="$(nix hash convert --to sri "sha256:$x86_hex")"

if [ -f "$metadata_file" ]; then
  current_version="$(jq -r '.version // empty' "$metadata_file")"
  current_arm_hash="$(jq -r '.darwin.aarch64.hash // empty' "$metadata_file")"
  current_x86_hash="$(jq -r '.darwin.x86_64.hash // empty' "$metadata_file")"

  if [ "$current_version" = "$version" ] \
    && [ "$current_arm_hash" = "$arm_hash" ] \
    && [ "$current_x86_hash" = "$x86_hash" ]; then
    echo "Betterbird metadata is already up to date at $version"
    exit 0
  fi
fi

updated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

jq -n \
  --arg version "$version" \
  --arg updated_at "$updated_at" \
  --arg arm_hash "$arm_hash" \
  --arg x86_hash "$x86_hash" \
  '{
    version: $version,
    updated_at: $updated_at,
    darwin: {
      aarch64: {
        os: "mac-arm64",
        artifact: "mac-arm64.dmg",
        hash: $arm_hash
      },
      x86_64: {
        os: "mac",
        artifact: "mac.dmg",
        hash: $x86_hash
      }
    }
  }' > "$metadata_file"

echo "Updated Betterbird to $version"
echo "aarch64-darwin: $arm_hash"
echo "x86_64-darwin: $x86_hash"
