{
  description = "Pinned Betterbird flake for Linux and Darwin";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
      systems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      lib = {
        metadata = metadata;
        currentVersion = metadata.version;
        availableVersions = metadata.available_versions;
      };

      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          betterbird = pkgs.callPackage ./package.nix { inherit metadata; };
        in
        {
          inherit betterbird;
          default = betterbird;
        });
    };
}
