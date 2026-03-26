{
  lib,
  stdenvNoCC,
  fetchurl,
  undmg,
  metadata,
}:

let
  pname = "betterbird";
  version = metadata.version;
  platform = stdenvNoCC.hostPlatform.system;
  releaseKey = {
    aarch64-darwin = "aarch64";
    x86_64-darwin = "x86_64";
  }.${platform} or (throw "Unsupported system: ${platform}");
  release = metadata.darwin.${releaseKey};
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://www.betterbird.eu/downloads/get.php?os=${release.os}&lang=en-US&version=release";
    name = "${pname}-${version}.en-US.${release.artifact}";
    hash = release.hash;
  };

  sourceRoot = ".";
  nativeBuildInputs = [ undmg ];

  # The upstream DMG ships a signed app bundle; avoid fixups that would break the signature.
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    shopt -s nullglob
    apps=(Betterbird*.app betterbird*.app)

    if [ "''${#apps[@]}" -ne 1 ]; then
      echo "Expected exactly one Betterbird app bundle, found: ''${apps[*]}" >&2
      exit 1
    fi

    mv "''${apps[0]}" "$out/Applications/Betterbird.app"

    runHook postInstall
  '';

  meta = {
    description = "Betterbird mail client for macOS";
    homepage = "https://www.betterbird.eu/";
    license = lib.licenses.mpl20;
    mainProgram = "Betterbird";
    platforms = lib.platforms.darwin;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
