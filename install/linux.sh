runHook preInstall

mkdir -p "$out/lib"
cp -r . "$out/lib/betterbird"

mkdir -p "$out/bin"
ln -s "$out/lib/betterbird/betterbird" "$out/bin/betterbird"

mkdir -p "$out/share/applications"
cat > "$out/share/applications/betterbird.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Betterbird
GenericName=Mail Client
Comment=Betterbird mail client
Exec=$out/bin/betterbird %u
Terminal=false
Icon=betterbird
Categories=Network;Email;
MimeType=x-scheme-handler/mailto;
StartupWMClass=betterbird
EOF

for size in 16 22 24 32 48 64 128 256; do
  mkdir -p "$out/share/icons/hicolor/${size}x${size}/apps"
  ln -s "$out/lib/betterbird/chrome/icons/default/default${size}.png" \
    "$out/share/icons/hicolor/${size}x${size}/apps/betterbird.png"
done

mkdir -p "$out/share/icons/hicolor/scalable/apps"
ln -s "$out/lib/betterbird/chrome/icons/default/default.svg" \
  "$out/share/icons/hicolor/scalable/apps/betterbird.svg"

gappsWrapperArgs+=(--argv0 "$out/bin/.betterbird-wrapped")

runHook postInstall
