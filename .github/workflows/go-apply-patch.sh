#!/bin/bash

set -euo pipefail

function join_by {
    local d=${1-} f=${2-}
    if shift 2; then
        printf '%s' "$f" "${@/#/$d}"
    fi
}

# create a mapping between short version and new version, e.g. 1.16 -> 1.16.3
declare -A VERSIONS
for version_new in ${VERSIONS_NEW}; do
  VERSIONS["${version_new%.*}"]="${version_new}"
done

. .github/workflows/common.sh

prepare_git_repo

branch_name="go-$(join_by '-and-' ${VERSIONS_NEW})-${TARGET}"

if ! checkout_branches "${branch_name}"; then
  exit 0
fi

# Parse the Manifest file for already present source files and keep the latest version in the current series
# DIST go1.17.src.tar.gz ... => 1.17
# DIST go1.17.1.src.tar.gz ... => 1.17.1
declare -a UPDATED_VERSIONS_OLD UPDATED_VERSIONS_NEW
any_different=0
for version_short in "${!VERSIONS[@]}"; do
  pushd "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" >/dev/null || exit
  VERSION_NEW="${VERSIONS["${version_short}"]}"
  VERSION_OLD=$(sed -n "s/^DIST go\(${version_short}\(\.*[0-9]*\)\?\)\.src.*/\1/p" dev-lang/go/Manifest | sort -ruV | head -n1)
  if [[ "${VERSION_NEW}" = "${VERSION_OLD}" ]]; then
    echo "${version_short} is already at the latest (${VERSION_NEW}), skipping"
    popd >/dev/null || exit
    continue
  fi
  UPDATED_VERSIONS_OLD+=("${VERSION_OLD}")
  UPDATED_VERSIONS_NEW+=("${VERSION_NEW}")

  any_different=1
  EBUILD_FILENAME=$(get_ebuild_filename "dev-lang" "go" "${VERSION_OLD}")
  git mv "${EBUILD_FILENAME}" "dev-lang/go/go-${VERSION_NEW}.ebuild"

  popd >/dev/null || exit

  generate_patches dev-lang go Go
done

if [[ $any_different -eq 0 ]]; then
  echo "go packages were already at the latest versions, nothing to do"
  exit 0
fi

apply_patches

vo_gh="$(join_by ' and ' ${VERSIONS_OLD})"
vn_gh="$(join_by ' and ' ${VERSIONS_NEW})"

echo ::set-output name=VERSIONS_OLD::"${vo_gh}"
echo ::set-output name=VERSIONS_NEW::"${vn_gh}"
echo ::set-output name=BRANCH_NAME::"${branch_name}"
echo ::set-output name=UPDATE_NEEDED::"1"
