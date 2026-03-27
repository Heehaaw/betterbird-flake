# betterbird-flake

Pinned Betterbird flake for Linux and Darwin.

This repository stores committed `en-US` Betterbird release metadata in `metadata.json` for Linux `x86_64`, Windows `x86_64` installer and portable builds, and Darwin `x86_64` and `aarch64`.

The flake exposes installable package outputs for:

- `x86_64-linux`
- `x86_64-darwin`
- `aarch64-darwin`

Windows artifacts remain metadata-only.

A daily GitHub Actions workflow runs `update.sh` and only commits when upstream Betterbird metadata changes.

## Outputs

- `lib.metadata`
- `lib.currentVersion`
- `lib.availableVersions`
- `packages.x86_64-linux.default`
- `packages.aarch64-darwin.default`
- `packages.x86_64-darwin.default`
- `packages.<system>.betterbird`

## Downstream Usage

```nix
{
  inputs.betterbird.url = "github:Heehaaw/betterbird-flake";
}
```

Then consume:

```nix
betterbird.packages.${pkgs.stdenv.hostPlatform.system}.default
```

If you need the pinned metadata directly, use `betterbird.lib.metadata`.

To output the tracked Betterbird versions from the flake:

```bash
nix eval --json .#lib.availableVersions
```

## Refreshing Metadata

The scheduled workflow runs `bash ./update.sh` once per day and on manual dispatch. The script updates `metadata.json` when Betterbird publishes a new `en-US` release for the tracked Linux, Windows, or Darwin artifacts, and refreshes the list of versions available in the current and previous release lines.
