#!/usr/bin/env bash
# Reproducibly rebuild the bundled cloud_redirect.so.
#
# Clones CloudRedirect at the pinned upstream commit, applies our patch
# (slsteammoon-cloudredirect.patch), and builds a 32-bit .so. The result is
# copied next to this script as cloud_redirect.so.
#
# BASE_COMMIT must always track upstream's actual latest -- headcrab always
# fetches whatever .so sits here, so a stale pin means every install gets a
# stale build. When upstream moves, re-pin BASE_COMMIT, re-run this script,
# and if it fails to apply, reconcile the patch against the new base first
# (some hunks may already be superseded by upstream's own fix -- check before
# re-adding them; see git log for how the steam_kv_injector.cpp rebase onto
# 178a6de dropped our GOT-decode hunk once upstream shipped its own).
#
# Usage:  ./build.sh
#
# Prefers podman/docker + the pinned glibc-2.35 image (Dockerfile.builder) for
# a build portable across older-glibc distros. Falls back to building
# natively with whatever toolchain is on PATH when neither is available --
# fine for building-and-deploying on the SAME machine, but the result may
# require a newer glibc than some end-user systems ship (the script still
# warns, but does not block, in that case).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPSTREAM="https://github.com/Selectively11/CloudRedirect.git"
BASE_COMMIT="178a6dea888f1de31e1ec9040e49ae3bf4d4e9e9"  # pinned upstream HEAD (v2.1.8-final)
IMAGE="slsteammoon-cloudredirect-builder"
WORK="$HERE/.build-src"

echo "==> fetching upstream @ $BASE_COMMIT"
rm -rf "$WORK"
git clone --no-checkout "$UPSTREAM" "$WORK"
git -C "$WORK" checkout "$BASE_COMMIT"

echo "==> applying slsteam-moon patch"
git -C "$WORK" apply "$HERE/slsteammoon-cloudredirect.patch"

runtime=""
for c in podman docker; do
	if command -v "$c" >/dev/null 2>&1; then runtime="$c"; break; fi
done

if [ -n "$runtime" ]; then
	echo "==> building builder image ($IMAGE)"
	"$runtime" build -f "$HERE/Dockerfile.builder" -t "$IMAGE" "$HERE"

	echo "==> building 32-bit cloud_redirect.so in container ($runtime)"
	"$runtime" run --rm -v "$WORK":/build:Z -w /build "$IMAGE" bash -c '
	  set -e
	  cmake -S . -B _b -DLINUX_32BIT=ON -DCMAKE_BUILD_TYPE=Release \
	        -DCMAKE_C_COMPILER=gcc-12 -DCMAKE_CXX_COMPILER=g++-12 >/dev/null
	  cmake --build _b --target cloud_redirect -j"$(nproc)"
	'
else
	echo "==> podman/docker not found; building natively (this machine's toolchain)"
	cmake -S "$WORK" -B "$WORK/_b" -DLINUX_32BIT=ON -DCMAKE_BUILD_TYPE=Release >/dev/null
	cmake --build "$WORK/_b" --target cloud_redirect -j"$(nproc)"
fi

cp -f "$WORK/_b/cloud_redirect.so" "$HERE/cloud_redirect.so"
chmod 755 "$HERE/cloud_redirect.so"
rm -rf "$WORK"

echo "==> done: $HERE/cloud_redirect.so"
file "$HERE/cloud_redirect.so"
# Sanity: must be 32-bit, must NOT require glibc newer than the Steam runtime.
if file -b "$HERE/cloud_redirect.so" | grep -q "ELF 32-bit"; then
	echo "OK: 32-bit"
else
	echo "ERROR: not 32-bit" >&2; exit 1
fi
if readelf -V "$HERE/cloud_redirect.so" 2>/dev/null | grep -qE "GLIBC_ABI_GNU_TLS|GLIBC_2\.3[6-9]|GLIBC_2\.4[0-9]"; then
	if [ -n "$runtime" ]; then
		echo "ERROR: links against too-new glibc despite the pinned container -- Dockerfile.builder may need updating" >&2
		exit 1
	fi
	echo "WARN: links against glibc newer than the portable baseline (expected for a" >&2
	echo "      native build -- fine if every install target's glibc is at least as" >&2
	echo "      new; NOT safe to redistribute as the one bundled .so for all distros" >&2
	echo "      headcrab supports without re-running this with podman/docker)." >&2
else
	echo "OK: glibc symbols within Steam-runtime range"
fi
