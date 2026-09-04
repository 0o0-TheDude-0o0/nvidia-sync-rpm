# NVIDIA Sync RPM

Builds a Fedora/RHEL-compatible RPM from NVIDIA's official `nvidia-sync` Debian package.

The GitHub Actions workflow runs on demand and whenever a GitHub release is published. It downloads the requested `.deb`, preserves its filesystem payload and metadata, and produces an `.rpm` attached to the workflow run. The source URL can be overridden with `DEB_URL` when dispatching the workflow.

## Local build

On a Fedora-like system with `rpmbuild`, `dpkg-deb`, and `curl` installed:

```bash
./build-rpm.sh https://workbench.download.nvidia.com/stable/linux/debian/pool/proprietary/n/nvidia-sync/nvidia-sync_0.117.3_amd64.deb
```

The resulting RPM is written to `dist/`. The NVIDIA endpoint may require access that is unavailable from some networks; the GitHub-hosted runner retries with a standard user agent and fails clearly if the URL is not accessible.

## Notes

This is a repackaging of NVIDIA's binary package, not a rebuild. Review the package contents and licensing before distributing it. RPM dependency metadata is intentionally conservative because Debian and RPM dependency names are not interchangeable.
