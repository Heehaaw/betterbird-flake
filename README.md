# betterbird-flake

Pinned Betterbird flake for Darwin.

This repository stores committed Betterbird release metadata in `metadata.json` and exposes pinned Darwin packages through flake outputs. A daily GitHub Actions workflow runs `update.sh` and only commits when upstream Betterbird metadata changes.

## Outputs

- `lib.metadata`
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

## Refreshing Metadata

The scheduled workflow runs `bash ./update.sh` once per day and on manual dispatch. The script updates `metadata.json` when Betterbird publishes a new Darwin release.
