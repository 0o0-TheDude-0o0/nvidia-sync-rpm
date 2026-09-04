#!/usr/bin/env bash
set -Eeuo pipefail

fallback='https://workbench.download.nvidia.com/stable/linux/debian/pool/proprietary/n/nvidia-sync/nvidia-sync_0.117.3_amd64.deb'
base='https://workbench.download.nvidia.com/stable/linux/debian'

for index in \
  "$base/dists/stable/main/binary-amd64/Packages.gz" \
  "$base/dists/stable/proprietary/binary-amd64/Packages.gz"; do
  if data="$(curl --fail --silent --show-error --retry 2 --user-agent 'nvidia-sync-rpm-builder/1.0' "$index" | gzip -dc 2>/dev/null)"; then
    filename="$(awk -v RS='' '$0 ~ /(^|\n)Package: nvidia-sync(\n|$)/ { if (match($0, /(^|\n)Filename: [^\n]+/)) { line=substr($0, RSTART, RLENGTH); sub(/^\n?Filename: /, "", line); print line; exit } }' <<<"$data")"
    if [[ -n "$filename" ]]; then
      [[ "$filename" == http* ]] && echo "$filename" || echo "$base/$filename"
      exit 0
    fi
  fi
done

echo "$fallback"
