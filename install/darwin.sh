runHook preInstall

mkdir -p "$out/Applications"
shopt -s nullglob
apps=(Betterbird*.app betterbird*.app)

if [ "${#apps[@]}" -ne 1 ]; then
  echo "Expected exactly one Betterbird app bundle, found: ${apps[*]}" >&2
  exit 1
fi

mv "${apps[0]}" "$out/Applications/Betterbird.app"

runHook postInstall
