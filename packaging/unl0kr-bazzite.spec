# unl0kr (from upstream BuffyBox, unmodified) packaged with a dracut module
# so it can replace Plymouth as the LUKS password prompt on handhelds.
%global debug_package %{nil}

Name:           unl0kr-bazzite
Version:        %{upstream_version}
Release:        1%{?dist}
Summary:        On-screen keyboard disk unlocker (unl0kr) with dracut integration
License:        GPL-3.0-or-later
URL:            https://gitlab.postmarketos.org/postmarketOS/buffybox
Source0:        buffybox-%{version}.tar.gz
Source1:        bazzite-touch-unlock-extra.tar.gz

BuildRequires:  gcc
BuildRequires:  meson
BuildRequires:  ninja-build
BuildRequires:  scdoc
BuildRequires:  pkgconfig(libinput)
BuildRequires:  pkgconfig(xkbcommon)
BuildRequires:  pkgconfig(libudev)
BuildRequires:  pkgconfig(inih)
BuildRequires:  pkgconfig(libdrm)
BuildRequires:  pkgconfig(systemd)
BuildRequires:  systemd
Requires:       dracut
Requires:       xkeyboard-config

%description
unl0kr is a touchscreen/mouse-driven on-screen keyboard for unlocking
encrypted disks from the initramfs, from the postmarketOS BuffyBox project.
This package adds a dracut module ("unl0kr") that installs unl0kr as the
systemd password agent in place of Plymouth, plus defaults for handhelds.

%prep
%setup -q -n buffybox -a 1

%build
meson setup _build \
    --prefix=%{_prefix} \
    --bindir=%{_bindir} \
    --libexecdir=%{_libexecdir} \
    --sysconfdir=%{_sysconfdir} \
    --datadir=%{_datadir} \
    --mandir=%{_mandir} \
    --buildtype=release \
    -Dsystemd=true
meson compile -C _build

%install
DESTDIR=%{buildroot} meson install -C _build --tags=unl0kr

install -Dm0755 extra/dracut/90unl0kr/module-setup.sh \
    %{buildroot}%{_prefix}/lib/dracut/modules.d/90unl0kr/module-setup.sh
install -Dm0644 extra/conf/50-handheld.conf \
    %{buildroot}%{_datadir}/unl0kr/unl0kr.conf.d/50-handheld.conf

# Fail loudly if upstream stopped installing the password agent.
find %{buildroot} -name 'unl0kr-agent' -type f | grep -q . \
    || { echo "unl0kr-agent was not built/installed" >&2; exit 1; }

# Build the file list from whatever upstream installed, so upstream path
# changes don't break packaging. Files under /etc become config files;
# man pages get a glob because rpmbuild compresses them afterwards.
( cd %{buildroot} && find . \( -type f -o -type l \) | sed 's|^\.||' | sort ) \
    | sed -E -e 's|^(/etc/.*)$|%config(noreplace) \1|' \
             -e 's|^(/usr/share/man/.*)$|\1*|' > %{_builddir}/unl0kr-files.list

%files -f %{_builddir}/unl0kr-files.list
%license COPYING

%changelog
* Sun Nov 08 2026 bazzite-touch-unlock - %{upstream_version}-1
- Package upstream unl0kr with a dracut module for handheld LUKS unlock
