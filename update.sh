#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
metadata_file="$repo_root/metadata.json"

downloads_page="$(curl -fsSL 'https://www.betterbird.eu/downloads/')"
current_version=""
previous_version=""

if [[ $downloads_page =~ Current[[:space:]]version:[[:space:]]Betterbird[[:space:]]([^[:space:]<]+) ]]; then
  current_version="${BASH_REMATCH[1]}"
fi

if [[ $downloads_page =~ Previous[[:space:]]version:[[:space:]]Betterbird[[:space:]]([^[:space:]<]+) ]]; then
  previous_version="${BASH_REMATCH[1]}"
fi

if [ -z "$current_version" ] || [ -z "$previous_version" ]; then
  echo "Unable to determine Betterbird versions from downloads page" >&2
  exit 1
fi

current_major="${current_version%%.*}"
previous_major="${previous_version%%.*}"
checksums="$(
  curl -fsSL "https://www.betterbird.eu/downloads/sha256-${current_major}.txt"

  if [ "$previous_major" != "$current_major" ]; then
    printf '\n'
    curl -fsSL "https://www.betterbird.eu/downloads/sha256-${previous_major}.txt"
  fi
)"

lookup_hex() {
  local file_name="$1"

  awk -v file_name="$file_name" '$2 == "*" file_name { print $1; exit }' <<< "$checksums"
}

to_sri() {
  nix hash convert --to sri "sha256:$1"
}

available_versions_json="$(
  printf '%s\n' "$checksums" \
    | tr '\r' '\n' \
    | grep -oE '(betterbird|BetterbirdPortable)-[^ ]+\.en-US\.(linux-x86_64\.tar\.(xz|bz2)|win64\.installer\.exe|win64\.zip|mac-arm64\.dmg|mac\.dmg)' \
    | sed -E 's/^(betterbird|BetterbirdPortable)-//; s/\.en-US\.(linux-x86_64\.tar\.(xz|bz2)|win64\.installer\.exe|win64\.zip|mac-arm64\.dmg|mac\.dmg)$//' \
    | awk '!seen[$0]++' \
    | jq -R . \
    | jq -c -s .
)"

linux_file_name="betterbird-${current_version}.en-US.linux-x86_64.tar.xz"
windows_installer_file_name="betterbird-${current_version}.en-US.win64.installer.exe"
windows_portable_file_name="BetterbirdPortable-${current_version}.en-US.win64.zip"
darwin_arm_file_name="betterbird-${current_version}.en-US.mac-arm64.dmg"
darwin_x86_file_name="betterbird-${current_version}.en-US.mac.dmg"

linux_hex="$(lookup_hex "$linux_file_name")"
windows_installer_hex="$(lookup_hex "$windows_installer_file_name")"
windows_portable_hex="$(lookup_hex "$windows_portable_file_name")"
darwin_arm_hex="$(lookup_hex "$darwin_arm_file_name")"
darwin_x86_hex="$(lookup_hex "$darwin_x86_file_name")"

if [ -z "$linux_hex" ] \
  || [ -z "$windows_installer_hex" ] \
  || [ -z "$windows_portable_hex" ] \
  || [ -z "$darwin_arm_hex" ] \
  || [ -z "$darwin_x86_hex" ]; then
  echo "Unable to find all expected checksum entries for Betterbird $current_version" >&2
  exit 1
fi

linux_hash="$(to_sri "$linux_hex")"
windows_installer_hash="$(to_sri "$windows_installer_hex")"
windows_portable_hash="$(to_sri "$windows_portable_hex")"
darwin_arm_hash="$(to_sri "$darwin_arm_hex")"
darwin_x86_hash="$(to_sri "$darwin_x86_hex")"

if [ -f "$metadata_file" ]; then
  current_metadata_version="$(jq -r '.version // empty' "$metadata_file")"
  current_available_versions="$(jq -c '.available_versions // []' "$metadata_file")"
  current_linux_hash="$(jq -r '.linux.x86_64.hash // empty' "$metadata_file")"
  current_windows_installer_hash="$(jq -r '.windows.x86_64.installer.hash // empty' "$metadata_file")"
  current_windows_portable_hash="$(jq -r '.windows.x86_64.portable.hash // empty' "$metadata_file")"
  current_darwin_arm_hash="$(jq -r '.darwin.aarch64.hash // empty' "$metadata_file")"
  current_darwin_x86_hash="$(jq -r '.darwin.x86_64.hash // empty' "$metadata_file")"

  if [ "$current_metadata_version" = "$current_version" ] \
    && [ "$current_available_versions" = "$available_versions_json" ] \
    && [ "$current_linux_hash" = "$linux_hash" ] \
    && [ "$current_windows_installer_hash" = "$windows_installer_hash" ] \
    && [ "$current_windows_portable_hash" = "$windows_portable_hash" ] \
    && [ "$current_darwin_arm_hash" = "$darwin_arm_hash" ] \
    && [ "$current_darwin_x86_hash" = "$darwin_x86_hash" ]; then
    echo "Betterbird metadata is already up to date at $current_version"
    exit 0
  fi
fi

updated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

jq -n \
  --arg version "$current_version" \
  --argjson available_versions "$available_versions_json" \
  --arg updated_at "$updated_at" \
  --arg linux_file_name "$linux_file_name" \
  --arg linux_hash "$linux_hash" \
  --arg windows_installer_file_name "$windows_installer_file_name" \
  --arg windows_installer_hash "$windows_installer_hash" \
  --arg windows_portable_file_name "$windows_portable_file_name" \
  --arg windows_portable_hash "$windows_portable_hash" \
  --arg darwin_arm_file_name "$darwin_arm_file_name" \
  --arg darwin_arm_hash "$darwin_arm_hash" \
  --arg darwin_x86_file_name "$darwin_x86_file_name" \
  --arg darwin_x86_hash "$darwin_x86_hash" \
  '{
    version: $version,
    available_versions: $available_versions,
    updated_at: $updated_at,
    linux: {
      x86_64: {
        os: "linux",
        file_name: $linux_file_name,
        artifact: "linux-x86_64.tar.xz",
        hash: $linux_hash
      }
    },
    windows: {
      x86_64: {
        installer: {
          os: "win",
          file_name: $windows_installer_file_name,
          artifact: "win64.installer.exe",
          hash: $windows_installer_hash
        },
        portable: {
          os: "win",
          portable: true,
          file_name: $windows_portable_file_name,
          artifact: "win64.zip",
          hash: $windows_portable_hash
        }
      }
    },
    darwin: {
      aarch64: {
        os: "mac-arm64",
        file_name: $darwin_arm_file_name,
        artifact: "mac-arm64.dmg",
        hash: $darwin_arm_hash
      },
      x86_64: {
        os: "mac",
        file_name: $darwin_x86_file_name,
        artifact: "mac.dmg",
        hash: $darwin_x86_hash
      }
    }
  }' > "$metadata_file"

echo "Updated Betterbird to $current_version"
echo "available_versions: $(printf '%s' "$available_versions_json" | jq 'length')"
echo "linux-x86_64: $linux_hash"
echo "windows-x86_64-installer: $windows_installer_hash"
echo "windows-x86_64-portable: $windows_portable_hash"
echo "aarch64-darwin: $darwin_arm_hash"
echo "x86_64-darwin: $darwin_x86_hash"
