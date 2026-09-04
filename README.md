# NVIDIA Sync Packages

Builds a Fedora/RHEL-compatible RPM and an AppImage from NVIDIA's official `nvidia-sync` Debian package.

The GitHub Actions workflow runs daily and on demand. It downloads the requested `.deb`, preserves its filesystem payload, and produces both an `.rpm` and an `.AppImage` attached to a versioned GitHub release. The source URL can be overridden when dispatching the workflow.

## Local build

On a Fedora-like system with `rpmbuild`, `dpkg-deb`, and `curl` installed:

```bash
./build-rpm.sh https://workbench.download.nvidia.com/stable/linux/debian/pool/proprietary/n/nvidia-sync/nvidia-sync_0.117.3_amd64.deb
```

The resulting RPM is written to `dist/`. The NVIDIA endpoint may require access that is unavailable from some networks; the GitHub-hosted runner retries with a standard user agent and fails clearly if the URL is not accessible.

## AppImage

On a system with `dpkg-deb`, `curl`, and `appimagetool` installed:

```bash
./build-appimage.sh https://workbench.download.nvidia.com/stable/linux/debian/pool/proprietary/n/nvidia-sync/nvidia-sync_0.117.3_amd64.deb
```

By default the launcher runs `usr/bin/nvidia-sync`. Override it with `APPIMAGE_ENTRYPOINT=path/inside/AppDir` if the package uses a different executable.

## Notes

This is a repackaging of NVIDIA's binary package, not a rebuild. Review the package contents and licensing before distributing it. RPM dependency metadata is intentionally conservative because Debian and RPM dependency names are not interchangeable.

An AppImage packages files for user-space execution; it does not automatically install systemd units, udev rules, kernel modules, or other privileged system integration from the Debian package.
