#!/bin/bash
set -euo pipefail

# Source: meta-qcom recipes-multimedia/camx/camxcommon-headers_1.0.12.bb.
readonly archive=camxcommon-headers_1.0.12_260708_armv8-2a.tar.gz
readonly url=https://qartifactory-edge.qualcomm.com/artifactory/qsc_releases/software/chip/component/camx.qclinux.0.0/260708/prebuilt_yocto_master/camxcommon-headers_1.0.12_armv8-2a.tar.gz
readonly sha256=3e4d94d6e15a1134a8302d0388683eefe62115b7d40fee06e564895c3176e48a
cd "$(dirname "$0")/.."

check_archive() {
    printf '%s  %s\n' "$sha256" "$1" | sha256sum --check --status
}

if [[ ! -f "$archive" ]]; then
    curl --fail --location --retry 2 --connect-timeout 20 --max-time 300 \
        --output "$archive.tmp" "$url"
    check_archive "$archive.tmp"
    mv "$archive.tmp" "$archive"
fi
if ! check_archive "$archive"; then
    echo "SHA256 mismatch: $archive; remove the invalid cache and retry." >&2
    exit 1
fi

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
tar --extract --gzip --file "$archive" --directory "$stage" --no-same-owner
# Keep the upstream directory layout; do not synthesize header aliases.
test -d "$stage/usr/include/camx-v1"
test -d "$stage/usr/include/camx-v2"
test -f "$stage/usr/share/doc/camxcommon-headers/LICENSE.QCOM-2.txt"
rm -rf camxcommon-headers
mkdir -p camxcommon-headers/usr/include camxcommon-headers/usr/share/doc/camxcommon-headers
cp -a "$stage/usr/include/." camxcommon-headers/usr/include/
install -m 0644 "$stage/usr/share/doc/camxcommon-headers/LICENSE.QCOM-2.txt" \
    camxcommon-headers/usr/share/doc/camxcommon-headers/
