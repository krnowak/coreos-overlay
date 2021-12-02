#!/bin/bash

set -euo pipefail

# trim the 3rd part in the input semver, e.g. from 1.14.3 to 1.14
VERSION_SHORT=${VERSION_NEW%.*}
UPDATE_NEEDED=1

. .github/workflows/common.sh

prepare_git_repo

if ! checkout_branches "go-${VERSION_NEW}-${TARGET}"; then
  UPDATE_NEEDED=0
  exit 0
fi

pushd "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" >/dev/null || exit

# Parse the Manifest file for already present source files and keep the latest version in the current series
# DIST go1.17.src.tar.gz ... => 1.17
# DIST go1.17.1.src.tar.gz ... => 1.17.1
VERSION_OLD=$(sed -n "s/^DIST go\(${VERSION_SHORT}\.*[0-9]*\)\.src.*/\1/p" dev-lang/go/Manifest | sort -ruV | head -n1)
if [[ "${VERSION_NEW}" = "${VERSION_OLD}" ]]; then
  echo "already the latest Go, nothing to do"
  UPDATE_NEEDED=0
  exit 0
fi

EBUILD_FILENAME=$(get_ebuild_filename "dev-lang" "go" "${VERSION_OLD}")
git mv "${EBUILD_FILENAME}" "dev-lang/go/go-${VERSION_NEW}.ebuild"

popd >/dev/null || exit

URL="https://go.googlesource.com/go/+/refs/tags/go${VERSION_NEW}"

generate_update_changelog 'Go' "${VERSION_NEW}" "${URL}" 'golang'

generate_patches dev-lang go Go

apply_patches

echo ::set-output name=VERSION_OLD::"${VERSION_OLD}"
echo ::set-output name=UPDATE_NEEDED::"${UPDATE_NEEDED}"
