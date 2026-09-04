#!/usr/bin/env bash
set -Eeuo pipefail

DEB_URL="${1:?usage: $0 URL [output-dir] [appimagetool-path]}"
OUT_DIR="${2:-dist}"
APPIMAGETOOL="${3:-appimagetool}"
WORK_DIR="${TMPDIR:-/tmp}/nvidia-sync-appimage.$$"
trap 'rm -rf "$WORK_DIR"' EXIT

mkdir -p "$WORK_DIR" "$OUT_DIR"
deb="$WORK_DIR/package.deb"
curl --fail --location --retry 4 --retry-all-errors --user-agent 'nvidia-sync-appimage-builder/1.0' --output "$deb" "$DEB_URL"
command -v dpkg-deb >/dev/null || { echo 'dpkg-deb is required' >&2; exit 1; }
command -v "$APPIMAGETOOL" >/dev/null || { echo "appimagetool not found: $APPIMAGETOOL" >&2; exit 1; }

name="$(dpkg-deb -f "$deb" Package)"
version="$(dpkg-deb -f "$deb" Version | sed 's/-[^-]*$//; s/[^A-Za-z0-9._+]/./g')"
arch="$(dpkg-deb -f "$deb" Architecture)"
[[ "$arch" == amd64 ]] && arch=x86_64
appdir="$WORK_DIR/$name.AppDir"
mkdir -p "$appdir"
dpkg-deb --extract "$deb" "$appdir"

entrypoint="${APPIMAGE_ENTRYPOINT:-usr/bin/$name}"
if [[ ! -e "$appdir/$entrypoint" ]]; then
  echo "entrypoint not found: $entrypoint (set APPIMAGE_ENTRYPOINT to the package's executable)" >&2
  exit 1
fi
cat > "$appdir/AppRun" <<EOF
#!/bin/sh
HERE="\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd)"
exec "\$HERE/$entrypoint" "\$@"
EOF
chmod +x "$appdir/AppRun"

output="$OUT_DIR/${name}-${version}-${arch}.AppImage"
APPIMAGE_EXTRACT_AND_RUN=1 "$APPIMAGETOOL" "$appdir" "$output" >/dev/null
chmod +x "$output"
echo "appimage_path=$output"
echo "appimage_version=$version"
