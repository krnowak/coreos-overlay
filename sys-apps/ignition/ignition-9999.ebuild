# Copyright (c) 2015 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_PROJECT="flatcar-linux/ignition"
CROS_WORKON_LOCALNAME="ignition"
CROS_WORKON_REPO="git://github.com"
COREOS_GO_PACKAGE="github.com/coreos/ignition/v2"
COREOS_GO_GO111MODULE="off"
inherit coreos-go cros-workon systemd udev

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm64"
else
	CROS_WORKON_COMMIT="c43dd0805b83122a633ec6909af02eb88465e483" # tormath1/convert-v2-v3
	KEYWORDS="amd64 arm64"
fi

DESCRIPTION="Pre-boot provisioning utility"
HOMEPAGE="https://github.com/coreos/ignition"
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0/${PVR}"
IUSE=""

# need util-linux for libblkid at compile time
DEPEND="sys-apps/util-linux"

RDEPEND="
	sys-apps/coreutils
	sys-apps/gptfdisk
	sys-apps/shadow
	sys-apps/systemd
	sys-fs/btrfs-progs
	sys-fs/dosfstools
	sys-fs/e2fsprogs
	sys-fs/mdadm
	sys-fs/xfsprogs
"

RDEPEND+="${DEPEND}"

PATCHES=(
)

src_compile() {
	export GO15VENDOREXPERIMENT="1"
	GO_LDFLAGS="-X github.com/coreos/ignition/v2/internal/version.Raw=${PV} -X github.com/coreos/ignition/v2/internal/distro.selinuxRelabel=false -X github.com/coreos/ignition/v2/internal/distro.writeAuthorizedKeysFragment=false" || die
	go_build "${COREOS_GO_PACKAGE}/internal"
}

src_install() {
	newbin ${GOBIN}/internal ${PN}
}
