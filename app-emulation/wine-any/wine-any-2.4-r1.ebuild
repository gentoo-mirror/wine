# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PLOCALES="ar bg ca cs da de el en en_US eo es fa fi fr he hi hr hu it ja ko lt ml nb_NO nl or pa pl pt_BR pt_PT rm ro ru sk sl sr_RS@cyrillic sr_RS@latin sv te th tr uk wa zh_CN zh_TW"
PLOCALE_BACKUP="en"

inherit autotools eapi7-ver estack eutils flag-o-matic gnome2-utils multilib multilib-minimal pax-utils plocale toolchain-funcs virtualx xdg-utils

MY_PN="${PN%%-*}"
MY_P="${MY_PN}-${PV}"

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="https://source.winehq.org/git/wine.git"
	EGIT_BRANCH="master"
	inherit git-r3
	SRC_URI=""
	#KEYWORDS=""
else
	MAJOR_V=$(ver_cut 1)
	SRC_URI="https://dl.winehq.org/wine/source/${MAJOR_V}.x/${MY_P}.tar.xz"
	KEYWORDS="-* ~amd64 ~x86"
fi
S="${WORKDIR}/${MY_P}"

STAGING_P="wine-staging-${PV}"
STAGING_DIR="${WORKDIR}/${STAGING_P}"
D3D9_P="wine-d3d9-${PV}"
D3D9_DIR="${WORKDIR}/wine-d3d9-patches-${D3D9_P}"
GWP_V="20180120"
PATCHDIR="${WORKDIR}/gentoo-wine-patches"

DESCRIPTION="Free implementation of Windows(tm) on Unix, with optional external patchsets"
HOMEPAGE="https://www.winehq.org/"
SRC_URI="${SRC_URI}
	https://dev.gentoo.org/~np-hardass/distfiles/wine/gentoo-wine-patches-${GWP_V}.tar.xz
"

if [[ ${PV} == "9999" ]] ; then
	STAGING_EGIT_REPO_URI="https://github.com/wine-compholio/wine-staging.git"
	D3D9_EGIT_REPO_URI="https://github.com/sarnex/wine-d3d9-patches.git"
else
	SRC_URI="${SRC_URI}
	staging? ( https://github.com/wine-compholio/wine-staging/archive/v${PV}.tar.gz -> ${STAGING_P}.tar.gz )
	d3d9? ( https://github.com/sarnex/wine-d3d9-patches/archive/${D3D9_P}.tar.gz )"
fi

LICENSE="LGPL-2.1"
SLOT="${PV}"
IUSE="+abi_x86_32 +abi_x86_64 +alsa capi cups custom-cflags d3d9 dos +fontconfig +gecko gphoto2 gsm gstreamer +jpeg +lcms ldap +mono mp3 ncurses netapi nls odbc openal opencl +opengl osmesa oss +perl pcap pipelight +png pulseaudio +realtime +run-exes s3tc samba scanner selinux +ssl staging test themes +threads +truetype udev +udisks v4l vaapi +X +xcomposite xinerama +xml"
REQUIRED_USE="|| ( abi_x86_32 abi_x86_64 )
	X? ( truetype )
	elibc_glibc? ( threads )
	osmesa? ( opengl )
	pipelight? ( staging )
	s3tc? ( staging )
	test? ( abi_x86_32 )
	themes? ( staging )
	vaapi? ( staging )" # osmesa-opengl #286560 # X-truetype #551124

# FIXME: the test suite is unsuitable for us; many tests require net access
# or fail due to Xvfb's opengl limitations.
RESTRICT="test"

COMMON_DEPEND="
	X? (
		x11-libs/libXcursor[${MULTILIB_USEDEP}]
		x11-libs/libXext[${MULTILIB_USEDEP}]
		x11-libs/libXrandr[${MULTILIB_USEDEP}]
		x11-libs/libXi[${MULTILIB_USEDEP}]
		x11-libs/libXxf86vm[${MULTILIB_USEDEP}]
	)
	alsa? ( media-libs/alsa-lib[${MULTILIB_USEDEP}] )
	capi? ( net-libs/libcapi[${MULTILIB_USEDEP}] )
	cups? ( net-print/cups:=[${MULTILIB_USEDEP}] )
	d3d9? (
		media-libs/mesa[d3d9,egl,${MULTILIB_USEDEP}]
		x11-libs/libX11[${MULTILIB_USEDEP}]
		x11-libs/libXext[${MULTILIB_USEDEP}]
		x11-libs/libxcb[${MULTILIB_USEDEP}]
	)
	fontconfig? ( media-libs/fontconfig:=[${MULTILIB_USEDEP}] )
	gphoto2? ( media-libs/libgphoto2:=[${MULTILIB_USEDEP}] )
	gsm? ( media-sound/gsm:=[${MULTILIB_USEDEP}] )
	gstreamer? (
		media-libs/gstreamer:1.0[${MULTILIB_USEDEP}]
		media-plugins/gst-plugins-meta:1.0[${MULTILIB_USEDEP}]
	)
	jpeg? ( virtual/jpeg:0=[${MULTILIB_USEDEP}] )
	lcms? ( media-libs/lcms:2=[${MULTILIB_USEDEP}] )
	ldap? ( net-nds/openldap:=[${MULTILIB_USEDEP}] )
	mp3? ( >=media-sound/mpg123-1.5.0[${MULTILIB_USEDEP}] )
	ncurses? ( >=sys-libs/ncurses-5.2:0=[${MULTILIB_USEDEP}] )
	netapi? ( net-fs/samba[netapi(+),${MULTILIB_USEDEP}] )
	nls? ( sys-devel/gettext[${MULTILIB_USEDEP}] )
	odbc? ( dev-db/unixODBC:=[${MULTILIB_USEDEP}] )
	openal? ( media-libs/openal:=[${MULTILIB_USEDEP}] )
	opencl? ( virtual/opencl[${MULTILIB_USEDEP}] )
	opengl? (
		virtual/glu[${MULTILIB_USEDEP}]
		virtual/opengl[${MULTILIB_USEDEP}]
	)
	osmesa? ( >=media-libs/mesa-13[osmesa,${MULTILIB_USEDEP}] )
	pcap? ( net-libs/libpcap[${MULTILIB_USEDEP}] )
	png? ( media-libs/libpng:0=[${MULTILIB_USEDEP}] )
	pulseaudio? ( media-sound/pulseaudio[${MULTILIB_USEDEP}] )
	scanner? ( media-gfx/sane-backends:=[${MULTILIB_USEDEP}] )
	ssl? ( net-libs/gnutls:=[${MULTILIB_USEDEP}] )
	staging? ( sys-apps/attr[${MULTILIB_USEDEP}] )
	themes? (
		dev-libs/glib:2[${MULTILIB_USEDEP}]
		x11-libs/cairo[${MULTILIB_USEDEP}]
		x11-libs/gtk+:3[${MULTILIB_USEDEP}]
	)
	truetype? ( >=media-libs/freetype-2.0.0[${MULTILIB_USEDEP}] )
	udev? ( virtual/libudev:=[${MULTILIB_USEDEP}] )
	udisks? ( sys-apps/dbus[${MULTILIB_USEDEP}] )
	v4l? ( media-libs/libv4l[${MULTILIB_USEDEP}] )
	vaapi? ( x11-libs/libva[X,${MULTILIB_USEDEP}] )
	xcomposite? ( x11-libs/libXcomposite[${MULTILIB_USEDEP}] )
	xinerama? ( x11-libs/libXinerama[${MULTILIB_USEDEP}] )
	xml? (
		dev-libs/libxml2[${MULTILIB_USEDEP}]
		dev-libs/libxslt[${MULTILIB_USEDEP}]
	)"

RDEPEND="${COMMON_DEPEND}
	app-emulation/wine-desktop-common
	>app-eselect/eselect-wine-0.3
	!app-emulation/wine:0
	dos? ( >=games-emulation/dosbox-0.74_p20160629 )
	gecko? ( app-emulation/wine-gecko:2.47[abi_x86_32?,abi_x86_64?] )
	mono? ( app-emulation/wine-mono:4.7.0 )
	perl? (
		dev-lang/perl
		dev-perl/XML-Simple
	)
	pulseaudio? (
		realtime? ( sys-auth/rtkit )
	)
	s3tc? ( >=media-libs/libtxc_dxtn-1.0.1-r1[${MULTILIB_USEDEP}] )
	samba? ( >=net-fs/samba-3.0.25[winbind] )
	selinux? ( sec-policy/selinux-wine )
	udisks? ( sys-fs/udisks:2 )"

# tools/make_requests requires perl
DEPEND="${COMMON_DEPEND}
	sys-devel/flex
	>=sys-kernel/linux-headers-2.6
	virtual/pkgconfig
	virtual/yacc
	X? ( x11-base/xorg-proto )
	staging? (
		dev-lang/perl
		dev-perl/XML-Simple
	)
	xinerama? ( x11-base/xorg-proto )"

# These use a non-standard "Wine" category, which is provided by
# /etc/xdg/applications-merged/wine.menu
QA_DESKTOP_FILE="usr/share/applications/wine-browsedrive.desktop
usr/share/applications/wine-notepad.desktop
usr/share/applications/wine-uninstaller.desktop
usr/share/applications/wine-winecfg.desktop"

PATCHES=(
	"${PATCHDIR}/patches/${MY_PN}-1.5.26-winegcc.patch" #260726
	"${PATCHDIR}/patches/${MY_PN}-1.9.5-multilib-portage.patch" #395615
	"${PATCHDIR}/patches/${MY_PN}-1.6-memset-O3.patch" #480508
	"${PATCHDIR}/patches/${MY_PN}-2.0-multislot-apploader.patch" #310611
	"${PATCHDIR}/patches/freetype-2.8.1-segfault.patch" #631676
	"${PATCHDIR}/patches/freetype-2.8.1-drop-glyphs.patch" #631376
	"${PATCHDIR}/patches/${MY_PN}-2.0-rearrange-manpages.patch" #469418 #617864
)
PATCHES_BIN=(
	"${PATCHDIR}/patches/freetype-2.8.1-patch-fonts.patch" #631376
)

# https://bugs.gentoo.org/show_bug.cgi?id=635222
if [[ ${#PATCHES_BIN[@]} -ge 1 ]] || [[ ${PV} == 9999 ]]; then
	DEPEND+=" dev-util/patchbin"
fi

wine_compiler_check() {
	[[ ${MERGE_TYPE} = "binary" ]] && return 0

	# Ensure compiler support
	# (No checks here as of 2022)
	return 0
}

wine_build_environment_check() {
	[[ ${MERGE_TYPE} = "binary" ]] && return 0

	if use abi_x86_32 && use opencl && [[ "$(eselect opencl show 2> /dev/null)" == "intel" ]]; then
		eerror "You cannot build wine with USE=opencl because intel-ocl-sdk is 64-bit only."
		eerror "See https://bugs.gentoo.org/487864 for more details."
		eerror
		return 1
	fi
}

wine_env_vcs_vars() {
	local pn_live_var="${PN//[-+]/_}_LIVE_COMMIT"
	local pn_live_val="${pn_live_var}"
	eval pn_live_val='$'${pn_live_val}
	if [[ ! -z ${pn_live_val} ]]; then
		if use staging || use d3d9; then
			eerror "Because of the multi-repo nature of ${MY_PN}, ${pn_live_var}"
			eerror "cannot be used to set the commit. Instead, you may use the"
			eerror "environment variables:"
			eerror "  EGIT_OVERRIDE_COMMIT_WINE"
			eerror "  EGIT_OVERRIDE_COMMIT_WINE_COMPHOLIO_WINE_STAGING"
			eerror "  EGIT_OVERRIDE_COMMIT_SARNEX_WINE_D3D9_PATCHES"
			eerror
			return 1
		fi
	fi
	if [[ ! -z ${EGIT_COMMIT} ]]; then
		eerror "Commits must now be specified using the environment variables:"
		eerror "  EGIT_OVERRIDE_COMMIT_WINE"
		eerror "  EGIT_OVERRIDE_COMMIT_WINE_COMPHOLIO_WINE_STAGING"
		eerror "  EGIT_OVERRIDE_COMMIT_SARNEX_WINE_D3D9_PATCHES"
		eerror
		return 1
	fi
}

pkg_pretend() {
	wine_build_environment_check || die

	# Verify OSS support
	if use oss && ! use kernel_FreeBSD; then
		if ! has_version ">=media-sound/oss-4"; then
			eerror "You cannot build wine with USE=oss without having support from a"
			eerror "FreeBSD kernel or >=media-sound/oss-4 (only available through external repos)"
			eerror
			die
		fi
	fi
}

pkg_setup() {
	wine_build_environment_check || die
	wine_env_vcs_vars || die

	WINE_VARIANT="${PN#wine}-${PV}"
	WINE_VARIANT="${WINE_VARIANT#-}"

	MY_PREFIX="${EPREFIX}/usr/lib/wine-${WINE_VARIANT}"
	MY_DATAROOTDIR="${EPREFIX}/usr/share/wine-${WINE_VARIANT}"
	MY_DATADIR="${MY_DATAROOTDIR}"
	MY_DOCDIR="${EPREFIX}/usr/share/doc/${PF}"
	MY_INCLUDEDIR="${EPREFIX}/usr/include/wine-${WINE_VARIANT}"
	MY_LIBEXECDIR="${EPREFIX}/usr/libexec/wine-${WINE_VARIANT}"
	MY_LOCALSTATEDIR="${EPREFIX}/var/wine-${WINE_VARIANT}"
	MY_MANDIR="${MY_DATADIR}/man"
}

src_unpack() {
	if [[ ${PV} == "9999" ]] ; then
		EGIT_CHECKOUT_DIR="${S}" git-r3_src_unpack
		if use staging; then
			local CURRENT_COMMIT_WINE=${EGIT_VERSION}

			EGIT_CHECKOUT_DIR="${STAGING_DIR}" EGIT_REPO_URI="${STAGING_EGIT_REPO_URI}" git-r3_src_unpack

			local COMPAT_COMMIT_WINE=$("${STAGING_DIR}/patches/patchinstall.sh" --upstream-commit) || die

			if [[ "${CURRENT_COMMIT_WINE}" != "${COMPAT_COMMIT_WINE}" ]]; then
				einfo "The current Staging patchset is not guaranteed to apply on this WINE commit."
				einfo "If src_prepare fails, try emerging with the env var EGIT_OVERRIDE_COMMIT_WINE."
				einfo "Example: EGIT_OVERRIDE_COMMIT_WINE=${COMPAT_COMMIT_WINE} emerge -1 wine"
			fi
		fi
		if use d3d9; then
			EGIT_CHECKOUT_DIR="${D3D9_DIR}" EGIT_REPO_URI="${D3D9_EGIT_REPO_URI}" git-r3_src_unpack
		fi
	fi

	default

	plocale_find_changes "${S}/po" "" ".po"
}

src_prepare() {

	eapply_bin(){
		local patch
		for patch in ${PATCHES_BIN[@]}; do
			patchbin --nogit < "${patch}" || die
		done
	}

	local md5="$(md5sum server/protocol.def)"

	if use staging; then
		ewarn "Applying the Wine-Staging patchset. Any bug reports to the"
		ewarn "Wine bugzilla should explicitly state that staging was used."

		local STAGING_EXCLUDE=""
		STAGING_EXCLUDE="${STAGING_EXCLUDE} -W winhlp32-Flex_Workaround" # Avoid double patching https://bugs.winehq.org/show_bug.cgi?id=42132
		use pipelight || STAGING_EXCLUDE="${STAGING_EXCLUDE} -W Pipelight"

		# Launch wine-staging patcher in a subshell, using eapply as a backend, and gitapply.sh as a backend for binary patches
		ebegin "Running Wine-Staging patch installer"
		(
			set -- DESTDIR="${S}" --backend=eapply --no-autoconf --all ${STAGING_EXCLUDE}
			cd "${STAGING_DIR}/patches"
			source "${STAGING_DIR}/patches/patchinstall.sh"
		)
		eend $? || die "Failed to apply Wine-Staging patches"
	fi
	if use d3d9; then
		if use staging; then
			PATCHES+=( "${D3D9_DIR}/staging-helper.patch" )
		else
			PATCHES+=( "${D3D9_DIR}/d3d9-helper.patch" )
		fi
		PATCHES+=( "${D3D9_DIR}/wine-d3d9.patch" )
	fi

	default
	eapply_bin
	eautoreconf

	# Modification of the server protocol requires regenerating the server requests
	if [[ "$(md5sum server/protocol.def)" != "${md5}" ]]; then
		einfo "server/protocol.def was patched; running tools/make_requests"
		tools/make_requests || die #432348
	fi
	sed -i '/^UPDATE_DESKTOP_DATABASE/s:=.*:=true:' tools/Makefile.in || die
	if ! use run-exes; then
		sed -i '/^MimeType/d' loader/wine.desktop || die #117785
	fi

	# Edit wine.desktop to work for specific variant
	sed -e "/^Exec=/s/wine /wine-${WINE_VARIANT} /" -i loader/wine.desktop || die

	# hi-res default icon, #472990, https://bugs.winehq.org/show_bug.cgi?id=24652
	cp "${PATCHDIR}/files/oic_winlogo.ico" dlls/user32/resources/ || die

	plocale_get_locales > po/LINGUAS || die # otherwise wine doesn't respect LINGUAS

	# Fix manpage generation for locales #469418 and abi_x86_64 #617864
	# Requires wine-2.0-rearrange-manpages.patch

	# Duplicate manpages input files for wine64
	local f
	for f in loader/*.man.in; do
		cp ${f} ${f/wine/wine64} || die
	done
	# Add wine64 manpages to Makefile
	if use abi_x86_64; then
		sed -i "/wine.man.in/i \
			\\\twine64.man.in \\\\" loader/Makefile.in || die
		sed -i -E 's/(.*wine)(.*\.UTF-8\.man\.in.*)/&\
\164\2/' loader/Makefile.in || die
	fi

	rm_man_file(){
		local file="${1}"
		loc=${2}
		sed -i "/${loc}\.UTF-8\.man\.in/d" "${file}" || die
	}

	while read f; do
		plocale_for_each_disabled_locale rm_man_file "${f}"
	done < <(find -name "Makefile.in" -exec grep -q "UTF-8.man.in" "{}" \; -print)
}

src_configure() {
	wine_compiler_check || die

	export LDCONFIG=/bin/true
	use custom-cflags || strip-flags

	multilib-minimal_src_configure
}

multilib_src_configure() {
	local myconf=(
		--prefix="${MY_PREFIX}"
		--datarootdir="${MY_DATAROOTDIR}"
		--datadir="${MY_DATADIR}"
		--docdir="${MY_DOCDIR}"
		--includedir="${MY_INCLUDEDIR}"
		--libdir="${EPREFIX}/usr/$(get_libdir)/wine-${WINE_VARIANT}"
		--libexecdir="${MY_LIBEXECDIR}"
		--localstatedir="${MY_LOCALSTATEDIR}"
		--mandir="${MY_MANDIR}"
		--sysconfdir=/etc/wine
		$(use_with alsa)
		$(use_with capi)
		$(use_with lcms cms)
		$(use_with cups)
		$(use_with ncurses curses)
		$(use_with udisks dbus)
		$(use_with fontconfig)
		$(use_with ssl gnutls)
		$(use_enable gecko mshtml)
		$(use_with gphoto2 gphoto)
		$(use_with gsm)
		$(use_with gstreamer)
		--without-hal
		$(use_with jpeg)
		$(use_with ldap)
		$(use_enable mono mscoree)
		$(use_with mp3 mpg123)
		$(use_with netapi)
		$(use_with nls gettext)
		$(use_with openal)
		$(use_with opencl)
		$(use_with opengl)
		$(use_with osmesa)
		$(use_with oss)
		$(use_with pcap)
		$(use_with png)
		$(use_with pulseaudio pulse)
		$(use_with threads pthread)
		$(use_with scanner sane)
		$(use_enable test tests)
		$(use_with truetype freetype)
		$(use_with udev)
		$(use_with v4l)
		$(use_with X x)
		$(use_with xcomposite)
		$(use_with xinerama)
		$(use_with xml)
		$(use_with xml xslt)
	)

	use staging && myconf+=(
		--with-xattr
		$(use_with themes gtk3)
		$(use_with vaapi va)
	)
	use d3d9 && myconf+=( $(use_with d3d9 d3d9-nine) )

	local PKG_CONFIG AR RANLIB
	# Avoid crossdev's i686-pc-linux-gnu-pkg-config if building wine32 on amd64; #472038
	# set AR and RANLIB to make QA scripts happy; #483342
	tc-export PKG_CONFIG AR RANLIB

	if use amd64; then
		if [[ ${ABI} == amd64 ]]; then
			myconf+=( --enable-win64 )
		else
			myconf+=( --disable-win64 )
		fi

		# Note: using --with-wine64 results in problems with multilib.eclass
		# CC/LD hackery. We're using separate tools instead.
	fi

	ECONF_SOURCE=${S} \
	econf "${myconf[@]}"
	emake depend
}

multilib_src_test() {
	# FIXME: win32-only; wine64 tests fail with "could not find the Wine loader"
	if [[ ${ABI} == x86 ]]; then
		if [[ $(id -u) == 0 ]]; then
			ewarn "Skipping tests since they cannot be run under the root user."
			ewarn "To run the test ${MY_PN} suite, add userpriv to FEATURES in make.conf"
			return
		fi

		WINEPREFIX="${T}/.wine-${ABI}" \
		Xemake test
	fi
}

multilib_src_install_all() {
	local DOCS=( ANNOUNCE AUTHORS README )
	add_locale_docs() {
		local locale_doc="documentation/README.$1"
		[[ ! -e ${locale_doc} ]] || DOCS+=( ${locale_doc} )
	}
	plocale_for_each_locale add_locale_docs

	einstalldocs
	prune_libtool_files --all

	if ! use perl ; then # winedump calls function_grep.pl, and winemaker is a perl script
		rm "${D%/}${MY_PREFIX}"/bin/{wine{dump,maker},function_grep.pl} \
			"${D%/}${MY_MANDIR}"/man1/wine{dump,maker}.1 || die
	fi

	# Remove wineconsole if neither backend is installed #551124
	if ! use X && ! use ncurses; then
		rm "${D%/}${MY_PREFIX}"/bin/wineconsole* || die
		rm "${D%/}${MY_MANDIR}"/man1/wineconsole* || die
		rm_wineconsole() {
			rm "${D%/}${MY_PREFIX}/$(get_libdir)"/wine/{,fakedlls/}wineconsole.exe* || die
		}
		multilib_foreach_abi rm_wineconsole
	fi

	use abi_x86_32 && pax-mark psmr "${D%/}${MY_PREFIX}"/bin/wine{,-preloader} #255055
	use abi_x86_64 && pax-mark psmr "${D%/}${MY_PREFIX}"/bin/wine64{,-preloader}

	if use abi_x86_64 && ! use abi_x86_32; then
		dosym wine64 "${MY_PREFIX}"/bin/wine # 404331
		dosym wine64-preloader "${MY_PREFIX}"/bin/wine-preloader
	fi

	# Failglob for binloops, shouldn't be necessary, but including to stay safe
	eshopts_push -s failglob #615218
	# Make wrappers for binaries for handling multiple variants
	# Note: wrappers instead of symlinks because some are shell which use basename
	local b
	for b in "${D%/}${MY_PREFIX}"/bin/*; do
		make_wrapper "${b##*/}-${WINE_VARIANT}" "${MY_PREFIX}/bin/${b##*/}"
	done
	eshopts_pop
}

pkg_postinst() {
	eselect wine register ${P}
	if [[ ${PN} == "wine-vanilla" ]]; then
		eselect wine register --vanilla ${P} || die
	else
		if use staging; then
			eselect wine register --staging ${P} || die
		fi
		if use d3d9; then
			eselect wine register --d3d9 ${P} || die
		fi
	fi

	eselect wine update --all --if-unset || die

	xdg_desktop_database_update

	if ! use gecko; then
		ewarn "Without Wine Gecko, wine prefixes will not have a default"
		ewarn "implementation of iexplore.  Many older windows applications"
		ewarn "rely upon the existence of an iexplore implementation, so"
		ewarn "you will likely need to install an external one, like via winetricks"
	fi
	if ! use mono; then
		ewarn "Without Wine Mono, wine prefixes will not have a default"
		ewarn "implementation of .NET.  Many windows applications rely upon"
		ewarn "the existence of a .NET implementation, so you will likely need"
		ewarn "to install an external one, like via winetricks"
	fi
}

pkg_prerm() {
	eselect wine deregister ${P}
	if [[ ${PN} == "wine-vanilla" ]]; then
		eselect wine deregister --vanilla ${P} || die
	else
		if use staging; then
			eselect wine deregister --staging ${P} || die
		fi
		if use d3d9; then
			eselect wine deregister --d3d9 ${P} || die
		fi
	fi

	eselect wine update --all --if-unset || die
}

pkg_postrm() {
	xdg_desktop_database_update
}
