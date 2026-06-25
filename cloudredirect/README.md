# Bundled CloudRedirect hook

Patched 32-bit build of [CloudRedirect](https://github.com/Selectively11/CloudRedirect),
giving unowned (lua) games Steam Cloud sync to the user's own Drive / OneDrive /
local folder. The installer deploys it (`crinstall()` in headcrab.sh); the
Steam wrapper injects it via `LD_PRELOAD`.

This patch must always track upstream's actual latest commit, not a
point-in-time snapshot -- headcrab fetches whatever `cloud_redirect.so` sits
in this directory on every install, so an out-of-date pin here means every
new install (and every CloudRedirect-app "Update available" prompt the user
accepts) regresses to vanilla. When upstream moves, bump `BASE_COMMIT` in
`build.sh` and re-run it; if the patch fails to apply, check whether upstream
already fixed the same thing a different way before re-adding our hunk for it.

Currently pinned at `b0acf20` (2.2.1-final). Fixes on top of upstream:

- **Attach wait 10s → 120s** — else the hook never attaches on slow-boot
  distros (Arch/CachyOS).
- **CAS SHA-leaf strip in the legacy path** — else old 2.0.x saves restore to a
  broken `<file>/<sha>` directory.
- **Worker-thread exception containment** — else one bad blob aborts the client.
- **Guarded KV reads (SIGSEGV/SIGBUS crash guard) in `ReadAppQuota` /
  `InjectAppQuota` / `InjectSaveFiles`** — a `steamclient.so` layout shift the
  sig-scan can't catch would otherwise SIGSEGV on a Steam worker thread and
  take the whole client down; a fault now just disables the KV injector for
  the session (quota falls back to a default, 1 GiB / 10000 files). Quota
  metadata only; save data is untouched.

Tracks Selectively11/CloudRedirect directly, not a third-party branch. We
briefly rebased onto unplausible's cloudredirect-moon (same fixes, since
slsteam-moon pairs with it), but unplausible privated all their repos --
depending on a fork of a fork for compatibility isn't worth it anyway.
Re-confirmed when rebasing back: Selectively11's own master never picked these
fixes up (it went a different direction -- Windows RVA tracking,
signature-failure recovery), so the patch is still genuinely needed and
applied cleanly, unmodified, straight onto current upstream HEAD.

## Rebuild

```sh
./build.sh   # clones upstream, applies the patch, builds, verifies
```

Prefers podman/docker with the pinned glibc-2.35 image (`Dockerfile.builder`)
for a build portable across older-glibc distros; falls back to building
natively with whatever's on `PATH` when neither is available (see `build.sh`
for the portability caveat that implies).

## Companion app

The `.so` only redirects cloud RPCs. Provider login (Drive / OneDrive OAuth) is
the upstream flatpak app (`org.cloudredirect.CloudRedirect`), fetched by the
installer when flatpak is present.
