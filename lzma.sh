package: lzma
version: "%(tag_basename)s"
tag: "v5.2.3"
source: https://github.com/alisw/liblzma
build_requires:
  - autotools
  - "GCC-Toolchain:(?!osx)"
prefer_system: "(?!slc5)"
prefer_system_check: |
  printf "#include <lzma.h>\n" | gcc -xc++ - -c -M 2>&1
---
#!/bin/bash -e

rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./
./autogen.sh
./configure CFLAGS="$CFLAGS -fPIC -Ofast" \
            --prefix="$INSTALLROOT"       \
            --disable-static              \
            --disable-nls                 \
            --disable-rpath               \
            --disable-dependency-tracking \
            --disable-doc
make ${JOBS+-j $JOBS} install
rm -f "$INSTALLROOT"/lib/*.la

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
setenv LZMA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib
prepend-path PATH \$::env(BASEDIR)/$PKGNAME/\$version/bin
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib")
EoF