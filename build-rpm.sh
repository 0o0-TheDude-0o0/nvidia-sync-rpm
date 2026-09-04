#!/usr/bin/env bash
set -Eeuo pipefail

DEB_URL="${1:?usage: $0 URL [output-dir]}"
OUT_DIR="${2:-dist}"
WORK_DIR="${TMPDIR:-/tmp}/nvidia-sync-rpm.$$"
trap 'rm -rf "$WORK_DIR"' EXIT

mkdir -p "$WORK_DIR" "$OUT_DIR"
deb="$WORK_DIR/package.deb"
curl --fail --location --retry 4 --retry-all-errors --user-agent 'nvidia-sync-rpm-builder/1.0' --output "$deb" "$DEB_URL"

command -v dpkg-deb >/dev/null || { echo 'dpkg-deb is required' >&2; exit 1; }
command -v rpmbuild >/dev/null || { echo 'rpmbuild is required' >&2; exit 1; }

name="$(dpkg-deb -f "$deb" Package)"
version="$(dpkg-deb -f "$deb" Version | sed 's/-[^-]*$//; s/[^A-Za-z0-9._+]/./g')"
release="1"
arch="$(dpkg-deb -f "$deb" Architecture)"
description="$(dpkg-deb -f "$deb" Description | head -n1 | sed 's/[[:space:]]*$//')"
[[ "$arch" == amd64 ]] && arch=x86_64

payload="$WORK_DIR/payload"
mkdir -p "$payload"
dpkg-deb --extract "$deb" "$payload"

spec="$WORK_DIR/$name.spec"
cat > "$spec" <<EOF
Name:           $name
Version:        $version
Release:        $release%{?dist}
Summary:        $description
License:        Proprietary
URL:            https://docs.nvidia.com/dgx/dgx-spark/nvidia-sync.html
BuildArch:      $arch

%description
$description

%prep

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}
cp -a $payload/. %{buildroot}/

%files
%defattr(-,root,root,-)
EOF

find "$payload" -mindepth 1 \( -type f -o -type l \) -printf '/%P\n' | LC_ALL=C sort >> "$spec"

rpmroot="$WORK_DIR/rpmroot"
mkdir -p "$rpmroot"
rpmbuild --define "_topdir $rpmroot" --define "_build_id_links none" -bb "$spec" >/dev/null
rpm="$(find "$rpmroot/RPMS" -type f -name '*.rpm' -print -quit)"
[[ -n "$rpm" ]] || { echo 'rpmbuild produced no RPM' >&2; exit 1; }
cp "$rpm" "$OUT_DIR/"
echo "rpm_path=$OUT_DIR/$(basename "$rpm")"
echo "rpm_version=$(rpm -qp --qf '%{VERSION}' "$rpm")"
