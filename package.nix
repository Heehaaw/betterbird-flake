{ lib
, stdenvNoCC
, fetchurl
, metadata
, undmg ? null
, autoPatchelfHook ? null
, wrapGAppsHook3 ? null
, patchelfUnstable ? null
, alsa-lib ? null
,
}:

let
  pname = "betterbird";
  version = metadata.version;
  platform = stdenvNoCC.hostPlatform.system;
  linuxInstallPhase = builtins.readFile ./install/linux.sh;
  darwinInstallPhase = builtins.readFile ./install/darwin.sh;
  release =
    if platform == "x86_64-linux" then
      metadata.linux.x86_64 // { kind = "linux"; }
    else if platform == "aarch64-darwin" then
      metadata.darwin.aarch64 // { kind = "darwin"; }
    else if platform == "x86_64-darwin" then
      metadata.darwin.x86_64 // { kind = "darwin"; }
    else
      throw "Unsupported system: ${platform}";
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://www.betterbird.eu/downloads/get.php?os=${release.os}&lang=en-US&version=release";
    name = "${pname}-${version}.en-US.${release.artifact}";
    hash = release.hash;
  };

  sourceRoot = if release.kind == "linux" then "betterbird" else ".";

  nativeBuildInputs =
    lib.optionals (release.kind == "linux") [
      autoPatchelfHook
      patchelfUnstable
      wrapGAppsHook3
    ]
    ++ lib.optionals (release.kind == "darwin") [
      undmg
    ];

  buildInputs = lib.optionals (release.kind == "linux") [ alsa-lib ];

  # Thunderbird uses relrhack, so keep autoPatchelf from clobbering old sections.
  patchelfFlags = lib.optionals (release.kind == "linux") [ "--no-clobber-old-sections" ];

  postPatch = lib.optionalString (release.kind == "linux") ''
    echo 'pref("app.update.auto", "false");' >> defaults/pref/channel-prefs.js
  '';

  # The upstream DMG ships a signed app bundle; avoid fixups that would break the signature.
  dontFixup = release.kind == "darwin";

  installPhase = if release.kind == "linux" then linuxInstallPhase else darwinInstallPhase;

  meta = {
    description = "Betterbird mail client";
    homepage = "https://www.betterbird.eu/";
    license = lib.licenses.mpl20;
    mainProgram = if release.kind == "linux" then "betterbird" else "Betterbird";
    platforms = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
