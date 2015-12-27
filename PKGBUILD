# Maintainer: schalox <schalox at gmail dot com>
# Contributor: Simon Zimmermann <simon@insmo.com>
# Contributor: Jon Yamokoski <code@jonyamo.us>

pkgname=passit-git
pkgver=20151226.3
pkgrel=1
pkgdesc='Retrieves lines from gpg encrypted files to stdout or clipboard'
license='GPL2'
arch=('any')
depends=('bash' 'gnupg' 'xclip')
makedepends=('git')
provides=('passit')
conflicts=('passit')
source=("$pkgname::git://github.com/pecheur/passit.git")
sha256sums=('SKIP')

pkgver() {
    cd "$pkgname"
    local _tmpver="$(git log -n 1 --format="%cd" --date=short)."
    local _tmpver+="$(git rev-list --count HEAD)"
    echo "${_tmpver//-/}"
}
package() {
    cd "$pkgname"
    make DESTDIR="${pkgdir}" install
}
