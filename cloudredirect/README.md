# Bundled CloudRedirect hook

32-bit build of [cloudredirect-moon](https://codeberg.org/unplausible/cloudredirect-moon)
(unplausible's branch of [CloudRedirect](https://github.com/Selectively11/CloudRedirect)
that slsteam-moon is designed to pair with), giving unowned (lua) games Steam
Cloud sync to the user's own Drive / OneDrive / local folder. The installer
deploys it (`crinstall()` in headcrab.sh); the Steam wrapper injects it via
`LD_PRELOAD`.

This must always track upstream's actual latest commit, not a point-in-time
snapshot -- headcrab fetches whatever `cloud_redirect.so` sits in this
directory on every install, so an out-of-date pin here means every new
install (and every CloudRedirect-app "Update available" prompt the user
accepts) regresses to vanilla. When upstream moves, bump `BASE_COMMIT` in
`build.sh` and re-run it.

Currently pinned at `d7d3469` (2.1.9), no local patch on top. This used to
carry `slsteammoon-cloudredirect.patch` (attach-wait 10s→120s so the hook
attaches on slow-boot distros, CAS SHA-leaf healing for old 2.0.x saves,
worker-thread exception containment, and a SIGSEGV/SIGBUS crash guard around
`ReadAppQuota` / `InjectAppQuota` / `InjectSaveFiles`) on top of raw
Selectively11/CloudRedirect. Rebasing onto cloudredirect-moon @ `d7d3469`
showed every one of those hunks now has a byte-for-byte equivalent fix
upstream (`511db1fe`, `b6ff6887`, `f12a6104`, `b7cbd787`, `bdf773c1`,
`247a59c3`, `508abdc7`), so the patch was dropped rather than carried forward
dead. If a future rebase needs a fork-specific fix again, check upstream's own
log first before re-adding a hunk for it -- this is the second time a carried
patch has turned out to be fully superseded (see prior history for the
steam_kv_injector.cpp GOT-decode hunk dropped at the `178a6de` rebase).

## Rebuild

```sh
./build.sh   # clones upstream, builds, verifies
```

Prefers podman/docker with the pinned glibc-2.35 image (`Dockerfile.builder`)
for a build portable across older-glibc distros; falls back to building
natively with whatever's on `PATH` when neither is available (see `build.sh`
for the portability caveat that implies).

## Companion app

The `.so` only redirects cloud RPCs. Provider login (Drive / OneDrive OAuth) is
the upstream flatpak app (`org.cloudredirect.CloudRedirect`), fetched by the
installer when flatpak is present.
