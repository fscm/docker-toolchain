# global args
ARG __PREFIX__="/usr/local/toolchain"
ARG __WORK_DIR__="/work"



FROM fscm/centos:8 as build

ARG __PREFIX__
ARG __WORK_DIR__
ARG AUTOCONF_VERSION="2.69"
ARG AUTOMAKE_VERSION="1.16.1"
ARG BINUTILS_VERSION="2.34"
ARG BISON_VERSION="3.5.3"
ARG BUSYBOX_VERSION="1.31.1"
ARG GCC_VERSION="9.3.0"
ARG GETTEXT_VERSION="0.20.1"
ARG GLIBC_VERSION="2.31"
ARG KERNEL_VERSION="5.5.13"
ARG LIBTOOL_VERSION="2.4.6"
ARG M4_VERSION="1.4.18"
ARG MAKE_VERSION="4.3"
ARG NCURSES_VERSION="6.2"
ARG PATCH_VERSION="2.7.6"
ARG ZLIB_VERSION="1.2.11"
ARG __BUILD_DIR__="/build"
ARG __SOURCE_DIR__="${__WORK_DIR__}/src"
ARG __USER__="root"

ENV \
  LANG="C.utf8" \
  LC_ALL="C.utf8" \
  PATH="${__PREFIX__}/bin:${PATH}"

USER ${__USER__}

COPY --chown=${__USER__}:${__USER__} "LICENSE" "files/" "${__WORK_DIR__}/"

WORKDIR "${__WORK_DIR__}"

RUN \
# dependencies
  echo '=== instaling dependencies ===' && \
  yum --assumeyes --quiet --enablerepo=PowerTools install \
    binutils \
    bison \
    byacc \
    bzip2 \
    coreutils-single \
    curl \
    diffutils \
    file \
    findutils \
    flex \
    gawk \
    gcc \
    gcc-c++ \
    gettext \
    glib2-static \
    glibc-static \
    gzip \
    libstdc++-static \
    m4 \
    make \
    patch \
    perl-Thread-Queue \
    python3-devel \
    rsync \
    sed \
    tar \
    texinfo \
    wget \
    xz && \
# build env
  echo '=== setting build env ===' && \
  set +h && \
  export __ARCH__="$(arch)" && \
  export __GNU_TYPE__="${__ARCH__}-fscm-linux-gnu" && \
  export __NPROC__="$(getconf _NPROCESSORS_ONLN || echo 1)" && \
  export __MAKEFLAGS__="--silent --output-sync --no-print-directory --jobs ${__NPROC__} V=0" && \
  export __PKG_VERSION__="fscm-$(date +%Y.%m.%d)" && \
  export MAKEFLAGS="${__MAKEFLAGS__}" && \
  export CONFIG_SITE="${__WORK_DIR__}/autoconf/config.site" && \
# build structure
  echo '=== creating build structure ===' && \
  for folder in ${__PREFIX__}; do install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "${__BUILD_DIR__}${folder}"; install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "$(dirname ${folder})"; ln --symbolic "${__BUILD_DIR__}${folder}" "${folder}"; done && \
  for folder in bin sbin; do install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "${__BUILD_DIR__}/usr/${folder}"; ln --symbolic "usr/${folder}" "${__BUILD_DIR__}/${folder}"; done && \
  for folder in tmp ${__WORK_DIR__}; do install --directory --owner=${__USER__} --group=${__USER__} --mode=1777 "${__BUILD_DIR__}/${folder}"; done && \
# copy tests
  echo '=== copying test files ===' && \
  install --owner=${__USER__} --group=${__USER__} --mode=0755 --target-directory="${__BUILD_DIR__}/usr/bin" ${__WORK_DIR__}/tests/* && \
# kernel headers
  echo '=== installing kernel headers ===' && \
  install --directory "${__SOURCE_DIR__}/kernel" && \
  curl --silent --location --retry 3 "https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_VERSION%%.*}.x/linux-${KERNEL_VERSION}.tar.xz" \
    | tar xJ --no-same-owner --strip-components=1 -C "${__SOURCE_DIR__}/kernel" --wildcards "*LICENSE*" "*COPYING*" $(echo linux-*/{Makefile,arch,include,scripts,tools,usr}) && \
  cd "${__SOURCE_DIR__}/kernel" && \
  make ARCH='x86' INSTALL_HDR_PATH="${__PREFIX__}" headers_install > /dev/null && \
  install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "${__PREFIX__}/licenses/linux" && \
  find ./ -type f -a \( -name '*LICENSE*' -o -name '*COPYING*' \) -exec cp --parents {} "${__PREFIX__}/licenses/linux" ';' && \
  cd - && \
  rm -rf "${__SOURCE_DIR__}/kernel" && \
# binutils (1)
  echo '=== installing binutils (1) ===' && \
  install --directory "${__SOURCE_DIR__}/binutils/_build" && \
  curl --silent --location --retry 3 "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.bz2" \
    | tar xj --no-same-owner --strip-components=1 -C "${__SOURCE_DIR__}/binutils" && \
  cd "${__SOURCE_DIR__}/binutils/_build" && \
  for file in $(grep -l 'sys_lib_dlsearch_path_spec=.*lt_ld_extra' ../*/configure); do \
    sed -i.orig -e '/sys_lib_dlsearch_path_spec=.*lt_ld_extra/ s,lib\( \+\|/\|$\),lib64\1,g' ${file}; \
  done && \
  sed -i.orig -e '/^scriptdir =/ s,lib\(/\|$\),lib64\1,' ../ld/Makefile.in && \
  find ../ -name '*.info' -exec touch {} ';' && \
  ../configure \
    --quiet \
    --target="${__GNU_TYPE__}" \
    --with-lib-path="${__PREFIX__}/lib64" \
    --with-pkgversion="${__PKG_VERSION__}" \
    --with-sysroot="/" \
    --without-debuginfod \
    --enable-ld \
    --disable-debug \
    --disable-gdb \
    --disable-gold \
    --disable-nls \
    --disable-sim \
    --disable-werror && \
  make MAKEINFO=true > /dev/null && \
  make MAKEINFO=true install-strip > /dev/null && \
  install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "${__PREFIX__}/licenses/binutils" && \
  (cd .. && find ./ -type f -a \( -name '*LICENSE*' -o -name '*COPYING*' \) -exec cp --parents {} "${__PREFIX__}/licenses/binutils" ';') && \
  cd - && \
  rm -rf "${__SOURCE_DIR__}/binutils/_build" && \
# gcc (1)
  echo '=== installing gcc (1) ===' && \
  install --directory "${__SOURCE_DIR__}/gcc/_build" && \
  curl --silent --location --retry 3 "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz" \
    | tar xJ --no-same-owner --strip-components=1 -C "${__SOURCE_DIR__}/gcc" && \
  cd "${__SOURCE_DIR__}/gcc/_build" && \
  sed -i.orig -e '/fetch/ s/wget/wget -q/' ../contrib/download_prerequisites && \
  (cd .. && ./contrib/download_prerequisites) && \
  sed -i.orig -e '/sys\/select.h/{:a;n;ba;q}' -e '/sys\/types.h/a #include <sys\/select.h>' ../libcc1/connection.cc && \
  sed -i.orig -e '/isl\/id.h/{:a;n;ba;q}' -e '/isl\/val.h/a #include <isl/id.h>\n#include <isl/space.h>' ../gcc/graphite.h && \
  find ../gcc/config{,/i386} -maxdepth 1 -type f -a \( -name 'linux.h' -o -name 'linux64.h' \) -exec sed -i.orig -e "s,/usr,${__PREFIX__},g" -e "s,/lib\(\|64\|32\)/ld,${__PREFIX__}&,g" {} ';' && \
  find ../gcc/config{,/i386} -maxdepth 1 -type f -a \( -name 'linux.h' -o -name 'linux64.h' \) -exec sh -c '/bin/echo -e "\n#undef STANDARD_STARTFILE_PREFIX_1\n#undef STANDARD_STARTFILE_PREFIX_2\n#define STANDARD_STARTFILE_PREFIX_1 \"${__PREFIX__}/lib64/\"\n#define STANDARD_STARTFILE_PREFIX_2 \"\"" >> {}' ';' && \
  find ../ -name '*.info' -exec touch {} ';' && \
  ../configure \
    --quiet \
    --target="${__GNU_TYPE__}" \
    --with-gcc-major-version-only \
    --with-glibc-version="${GLIBC_VERSION}" \
    --with-local-prefix="${__PREFIX__}" \
    --with-native-system-header-dir="${__PREFIX__}/include" \
    --with-newlib \
    --with-pkgversion="${__PKG_VERSION__}" \
    --with-sysroot="/" \
    --without-headers \
    --enable-__cxa_atexit \
    --enable-languages=c,c++ \
    --enable-silent-rules \
    --enable-tls \
    --disable-debug \
    --disable-decimal-float \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libquadmath \
    --disable-libquadmath-support \
    --disable-libssp \
    --disable-libstdcxx \
    --disable-libvtv \
    --disable-multilib \
    --disable-nls \
    --disable-shared \
    --disable-threads && \
  make MAKEINFO=true > /dev/null && \
  make MAKEINFO=true install-strip > /dev/null && \
  install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "${__PREFIX__}/licenses/gcc" && \
  (cd .. && find ./ -type f -a \( -name '*LICENSE*' -o -name '*COPYING*' \) -exec cp --parents {} "${__PREFIX__}/licenses/gcc" ';') && \
  cd - && \
  rm -rf "${__SOURCE_DIR__}/gcc/_build" && \
# glibc
  echo '=== installing glibc ===' && \
  install --directory "${__SOURCE_DIR__}/glibc/_build" && \
  curl --silent --location --retry 3 "https://ftp.gnu.org/gnu/glibc/glibc-${GLIBC_VERSION}.tar.xz" \
    | tar xJ --no-same-owner --strip-components=1 -C "${__SOURCE_DIR__}/glibc" && \
  cd "${__SOURCE_DIR__}/glibc/_build" && \
  sed -i.orig -e '/^\(\|root\)sbindir =/ s,/sbin,/bin,' -e '/^\(\|s\)libdir =/ s,/lib,/lib64,' ../Makeconfig && \
  sed -i.orig -e '/@BASH@/c #!/bin/sh' -e 's/$"/"/' -e '/read -p/c \ \ printf "Press return here to close %s(%s)." "$TERMINAL_PROG" "$program"; read'  ../debug/xtrace.sh && \
  sed -i.orig -e '/@BASH@/c #!/bin/sh' -e 's/$"/"/' ../elf/ldd.bash.in && \
  sed -i.orig -e '/@BASH@/c #!/bin/sh' -e 's/$"/"/' ../elf/sotruss.sh && \
  sed -i.orig -e 's,/bin/bash,/bin/sh,' ../timezone/tzselect.ksh && \
  find ../locale/programs -name '*-kw.h' -exec touch {} ';' && \
  find ../ -name 'configure' -exec touch {} ';' && \
  ../configure \
    --quiet \
    --build="$(../scripts/config.guess)" \
    --host="${__GNU_TYPE__}" \
    --with-__thread \
    --with-headers="${__PREFIX__}/include" \
    --with-pkgversion="${__PKG_VERSION__}" \
    --with-tls \
    --without-cvs \
    --without-gd \
    --without-selinux \
    --enable-add-ons \
    --enable-bind-now \
    --enable-kernel="3.2.0" \
    --enable-shared \
    --enable-stack-protector=strong \
    --enable-tunables \
    --disable-build-nscd \
    --disable-debug \
    --disable-nscd \
    --disable-profile \
    --disable-timezone-tools && \
  make > /dev/null && \
  make install > /dev/null && \
  install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "${__PREFIX__}/lib64/locale" && \
  ( ./locale/localedef --quiet --inputfile=POSIX --charmap=UTF-8 C.UTF-8 || true ) && \
  truncate --size=0 "${__PREFIX__}/etc/ld.so.conf" && \
  for folder in $(echo {${__PREFIX__},/usr{/local,},}/{lib64,lib}); do if [ -d ${folder} ]; then echo ${folder} >> "${__PREFIX__}/etc/ld.so.conf"; fi; done && \
  echo 'include /etc/ld.so.conf.d/*.conf' >> "${__PREFIX__}/etc/ld.so.conf" && \
  install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "${__PREFIX__}/licenses/glibc" && \
  (cd .. && find ./ -type f -a \( -name '*LICENSE*' -o -name '*COPYING*' \) -exec cp --parents {} "${__PREFIX__}/licenses/glibc" ';') && \
  cd - && \
  rm -rf "${__SOURCE_DIR__}/glibc" && \
# libstdc++
  echo '=== installing libstdc++ ===' && \
  install --directory "${__SOURCE_DIR__}/gcc/_build_libstdc" && \
  cd "${__SOURCE_DIR__}/gcc/_build_libstdc" && \
  ../libstdc++-v*/configure \
    --quiet \
    --host="${__GNU_TYPE__}" \
    --with-gcc-major-version-only \
    --with-gxx-include-dir="${__PREFIX__}/${__GNU_TYPE__}/include/c++/${GCC_VERSION%%.*}" \
    --enable-silent-rules \
    --enable-tls \
    --disable-libstdcxx-pch \
    --disable-libstdcxx-threads \
    --disable-multilib \
    --disable-nls && \
  make > /dev/null && \
  make install-strip > /dev/null && \
  cd - && \
  rm -rf "${__SOURCE_DIR__}/gcc/_build_libstdc" && \
# zlib
  echo '=== installing zlib ===' && \
  install --directory "${__SOURCE_DIR__}/zlib/_build" && \
  curl --silent --location --retry 3 "https://zlib.net/zlib-${ZLIB_VERSION}.tar.xz" \
    | tar xJ --no-same-owner --strip-components=1 -C "${__SOURCE_DIR__}/zlib" && \
  cd "${__SOURCE_DIR__}/zlib/_build" && \
  sed -i.orig -e "/^mandir=/ s,=.*,='\${prefix}/_delete_/share/man'," ../configure && \
  sed -i.orig -e "/^pkgconfigdir =/ s,= .*,= \${prefix}/_delete_/pkgconfig," ../Makefile.in && \
  AR="${__GNU_TYPE__}-ar" \
  CC="${__GNU_TYPE__}-gcc" \
  CPP="${__GNU_TYPE__}-gcc -E" \
  RANLIB="${__GNU_TYPE__}-ranlib" \
  ../configure \
    --prefix="${__PREFIX__}" \
    --libdir="${__PREFIX__}/lib64" \
    --sharedlibdir="${__PREFIX__}/lib64" \
    --includedir="${__PREFIX__}/include" \
    > /dev/null && \
  make > /dev/null && \
  make install > /dev/null && \
  install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "${__PREFIX__}/licenses/zlib" && \
  (cd .. && find ./ -type f -a \( -name '*LICENSE*' -o -name '*COPYING*' \) -exec cp --parents {} "${__PREFIX__}/licenses/zlib" ';') && \
  cd - && \
  rm -rf "${__SOURCE_DIR__}/zlib" && \
# binutils (2)
  echo '=== installing binutils (2) ===' && \
  install --directory "${__SOURCE_DIR__}/binutils/_build" && \
  cd "${__SOURCE_DIR__}/binutils/_build" && \
  AR="${__GNU_TYPE__}-ar" \
  CC="${__GNU_TYPE__}-gcc" \
  CXX="${__GNU_TYPE__}-g++" \
  RANLIB="${__GNU_TYPE__}-ranlib" \
  ../configure \
    --quiet \
    --with-gcc-major-version-only \
    --with-lib-path="${__PREFIX__}/lib64" \
    --with-pkgversion="${__PKG_VERSION__}" \
    --with-sysroot \
    --with-system-zlib \
    --without-debuginfod \
    --enable-64-bit-bfd \
    --enable-gold \
    --enable-host-shared \
    --enable-install-libiberty \
    --enable-ld=default \
    --enable-lto \
    --enable-plugins \
    --enable-shared \
    --enable-static \
    --enable-threads=posix \
    --disable-debug \
    --disable-gdb \
    --disable-nls \
    --disable-werror && \
  make MAKEINFO=true tooldir=${__PREFIX__} > /dev/null && \
  make MAKEINFO=true tooldir=${__PREFIX__} install-strip > /dev/null && \
  make MAKEINFO=true tooldir=${__PREFIX__} -C "./ld" clean > /dev/null && \
  make MAKEINFO=true tooldir=${__PREFIX__} -C "./ld" LIB_PATH="${__PREFIX__}/lib64:/usr/local/lib64:/usr/lib64:/lib64:/usr/local/lib:/usr/lib:/lib" > /dev/null && \
  make MAKEINFO=true tooldir=${__PREFIX__} -C "./ld" install-strip > /dev/null && \
  make MAKEINFO=true tooldir=${__PREFIX__} -C "./gold" clean > /dev/null && \
  make MAKEINFO=true tooldir=${__PREFIX__} -C "./gold" LIB_PATH="${__PREFIX__}/lib64:/usr/local/lib64:/usr/lib64:/lib64:/usr/local/lib:/usr/lib:/lib" > /dev/null && \
  make MAKEINFO=true tooldir=${__PREFIX__} -C "./gold" install-strip > /dev/null && \
  cd - && \
  rm -rf "${__SOURCE_DIR__}/binutils" && \
# gcc (2)
  echo '=== installing gcc (2) ===' && \
  install --directory "${__SOURCE_DIR__}/gcc/_build" && \
  cd "${__SOURCE_DIR__}/gcc/_build" && \
  cat ../gcc/{limitx.h,glimits.h,limity.h} > "$(dirname $(${__GNU_TYPE__}-gcc -print-libgcc-file-name))/include-fixed/limits.h" && \
  AR="${__GNU_TYPE__}-ar" \
  CC="${__GNU_TYPE__}-gcc" \
  CXX="${__GNU_TYPE__}-g++" \
  RANLIB="${__GNU_TYPE__}-ranlib" \
  ../configure \
    --quiet \
    --with-gcc-major-version-only \
    --with-glibc-version=2.11 \
    --with-local-prefix="${__PREFIX__}" \
    --with-native-system-header-dir="${__PREFIX__}/include" \
    --with-pkgversion="${__PKG_VERSION__}" \
    --with-system-zlib \
    --without-debuginfod \
    --enable-__cxa_atexit \
    --enable-host-shared \
    --enable-languages=c,c++ \
    --enable-libstdcxx-threads \
    --enable-silent-rules \
    --enable-shared \
    --enable-static \
    --enable-threads=posix \
    --enable-tls \
    --disable-bootstrap \
    --disable-debug \
    --disable-libgomp \
    --disable-libstdcxx-pch \
    --disable-multilib \
    --disable-nls && \
  make MAKEINFO=true tooldir=${__PREFIX__} > /dev/null && \
  make MAKEINFO=true tooldir=${__PREFIX__} install-strip > /dev/null && \
  ln --symbolic 'gcc' "${__PREFIX__}/bin/cc" && \
  ln --symbolic '../bin/cpp' "${__PREFIX__}/lib64/cpp" && \
  rm -rf "${__PREFIX__}/lib64/gcc/$(gcc -dumpmachine)/$(gcc -dumpversion)/include-fixed/bits" && \
  install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "${__PREFIX__}/lib64/bfd-plugins" && \
  ln --symbolic "../gcc/$(gcc -dumpmachine)/$(gcc -dumpversion)/liblto_plugin.so" "${__PREFIX__}/lib64/bfd-plugins" && \
  install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "${__PREFIX__}/share/gdb/auto-load/usr/lib64" && \
  mv "${__PREFIX__}/lib64/"*gdb.py "${__PREFIX__}/share/gdb/auto-load/usr/lib64" && \
  cd - && \
  rm -rf "${__SOURCE_DIR__}/gcc" && \
# cleanup
  echo '=== cleaning up ===' && \
  find "${__BUILD_DIR__}${__PREFIX__}" -depth -type d -name "${__GNU_TYPE__}" -exec rm -rf '{}' + && \
  find "${__BUILD_DIR__}${__PREFIX__}" -depth -type f -name "${__GNU_TYPE__}*" -delete && \
# m4
  echo '=== installing m4 ===' && \
  install --directory "${__SOURCE_DIR__}/m4/_build" && \
  curl --silent --location --retry 3 "https://ftp.gnu.org/gnu/m4/m4-${M4_VERSION}.tar.xz" \
    | tar xJ --no-same-owner --strip-components=1 -C "${__SOURCE_DIR__}/m4" && \
  cd "${__SOURCE_DIR__}/m4/_build" && \
  sed -i.orig -e 's/IO_ftrylockfile/IO_EOF_SEEN/' ../lib/*.c && \
  /usr/bin/echo -e '\n#if !defined _IO_IN_BACKUP && defined _IO_EOF_SEEN\n# define _IO_IN_BACKUP 0x100\n#endif' >> ../lib/stdio-impl.h && \
  ../configure \
    --quiet \
    --with-packager="${__PKG_VERSION__%%-*}" \
    --with-packager-version="${__PKG_VERSION__}" && \
  make --silent > /dev/null && \
  make --silent install-strip > /dev/null && \
  install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "${__PREFIX__}/licenses/m4" && \
  (cd .. && find ./ -type f -a \( -name '*LICENSE*' -o -name '*COPYING*' \) -exec cp --parents {} "${__PREFIX__}/licenses/m4" ';') && \
  cd - && \
  rm -rf "${__SOURCE_DIR__}/m4" && \
# ncurses
  echo '=== installing ncurses ===' && \
  install --directory "${__SOURCE_DIR__}/ncurses/_build" && \
  curl --silent --location --retry 3 "https://ftp.gnu.org/pub/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz" \
    | tar xz --no-same-owner --strip-components=1 -C "${__SOURCE_DIR__}/ncurses" && \
  cd "${__SOURCE_DIR__}/ncurses/_build" && \
  sed -i.orig -e '/^SHLIB_LIST/ s/@SHLIB_LIST@//' ../{c++,form,menu,panel}/Makefile.in && \
  sed -i.orig -e '/^TICDIR=/ s,/lib/,/lib64/,' ../misc/run_tic.in && \
  ../configure \
    --quiet \
    --with-abi-version=6 \
    --with-cxx-shared \
    --with-ospeed=unsigned \
    --with-pkg-config-libdir="${__PREFIX__}/_delete_/pkgconfig" \
    --with-shared \
    --with-terminfo-dirs="/etc/terminfo:${__PREFIX__}/share/terminfo" \
    --with-termlib=tinfo \
    --with-ticlib=tic \
    --with-xterm-kbs=DEL \
    --without-ada \
    --without-debug \
    --without-profile \
    --without-tests \
    --enable-colorfgbg \
    --enable-hard-tabs \
    --enable-xmc-glitch \
    --enable-widec \
    --disable-overwrite \
    --disable-pc-files \
    --disable-stripping \
    --disable-termcap \
    --disable-wattr-macros && \
  make libs > /dev/null && \
  make -C './progs' > /dev/null && \
  make install.{libs,progs,data,includes} > /dev/null && \
  for f in $(find "${__PREFIX__}/include/ncursesw" -type f); do lib="$(basename ${f})"; ln -s "ncursesw/${lib}" "${__PREFIX__}/include/${lib}"; done && \
  for l in $(find "${__PREFIX__}/include/ncursesw" -type l); do lib="$(basename ${l})"; dest="$(readlink ${l})"; ln -s "ncursesw/${dest}" "${__PREFIX__}/include/${lib}"; done && \
  ln -s "ncursesw" "${__PREFIX__}/include/ncurses" && \
  install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "${__PREFIX__}/licenses/ncurses" && \
  (cd .. && find ./ -type f -a \( -name '*LICENSE*' -o -name '*COPYING*' \) -exec cp --parents {} "${__PREFIX__}/licenses/ncurses" ';') && \
  cd - && \
  rm -rf "${__SOURCE_DIR__}/ncurses" && \
# gettext
  echo '=== installing gettext ===' && \
  install --directory "${__SOURCE_DIR__}/gettext/_build" && \
  curl --silent --location --retry 3 "https://ftp.gnu.org/pub/gnu/gettext/gettext-${GETTEXT_VERSION}.tar.xz" \
    | tar xJ --no-same-owner --strip-components=1 -C "${__SOURCE_DIR__}/gettext" && \
  cd "${__SOURCE_DIR__}/gettext/_build" && \
  ../configure \
    --quiet \
    --with-pic \
    --without-emacs \
    --enable-nls \
    --enable-shared \
    --enable-static \
    --disable-acl \
    --disable-csharp \
    --disable-java \
    --disable-native-java && \
  make > /dev/null && \
  make install-strip EXAMPLESFILES="" > /dev/null && \
  chmod 0755 "${__PREFIX__}/lib64/preloadable_libintl.so" && \
  install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "${__PREFIX__}/licenses/gettext" && \
  (cd .. && find ./ -type f -a \( -name '*LICENSE*' -o -name '*COPYING*' \) -exec cp --parents {} "${__PREFIX__}/licenses/gettext" ';') && \
  cd - && \
  rm -rf "${__SOURCE_DIR__}/gettext" && \
# make
  echo '=== installing make ===' && \
  install --directory "${__SOURCE_DIR__}/make/_build" && \
  curl --silent --location --retry 3 "https://ftp.gnu.org/gnu/make/make-${MAKE_VERSION}.tar.gz" \
    | tar xz --no-same-owner --strip-components=1 -C "${__SOURCE_DIR__}/make" && \
  cd "${__SOURCE_DIR__}/make/_build" && \
  ../configure \
    --quiet \
    --without-guile && \
  make > /dev/null && \
  make install-strip > /dev/null && \
  install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "${__PREFIX__}/licenses/make" && \
  (cd .. && find ./ -type f -a \( -name '*LICENSE*' -o -name '*COPYING*' \) -exec cp --parents {} "${__PREFIX__}/licenses/make" ';') && \
  cd - && \
  rm -rf "${__SOURCE_DIR__}/make" && \
# autoconf # <- create test
  echo '=== installing autoconf ===' && \
  install --directory "${__SOURCE_DIR__}/autoconf/_build" && \
  curl --silent --location --retry 3 "https://ftp.gnu.org/gnu/autoconf/autoconf-${AUTOCONF_VERSION}.tar.xz" \
    | tar xJ --no-same-owner --strip-components=1 -C "${__SOURCE_DIR__}/autoconf" && \
  cd "${__SOURCE_DIR__}/autoconf/_build" && \
  ../configure \
    --quiet && \
  make > /dev/null && \
  make install-strip > /dev/null && \
  install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "${__PREFIX__}/licenses/autoconf" && \
  (cd .. && find ./ -type f -a \( -name '*LICENSE*' -o -name '*COPYING*' \) -exec cp --parents {} "${__PREFIX__}/licenses/autoconf" ';') && \
  cd - && \
  rm -rf "${__SOURCE_DIR__}/autoconf" && \
# automake # <- create test
  echo '=== installing automake ===' && \
  install --directory "${__SOURCE_DIR__}/automake/_build" && \
  curl --silent --location --retry 3 "https://ftp.gnu.org/gnu/automake/automake-${AUTOMAKE_VERSION}.tar.xz" \
    | tar xJ --no-same-owner --strip-components=1 -C "${__SOURCE_DIR__}/automake" && \
  cd "${__SOURCE_DIR__}/automake/_build" && \
  ../configure \
    --quiet \
    --enable-silent-rules && \
  make > /dev/null && \
  make install-strip > /dev/null && \
  install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "${__PREFIX__}/licenses/automake" && \
  (cd .. && find ./ -type f -a \( -name '*LICENSE*' -o -name '*COPYING*' \) -exec cp --parents {} "${__PREFIX__}/licenses/automake" ';') && \
  cd - && \
  rm -rf "${__SOURCE_DIR__}/automake" && \
# bison # <- create test
  echo '=== installing bison ===' && \
  install --directory "${__SOURCE_DIR__}/bison/_build" && \
  curl --silent --location --retry 3 "https://ftp.gnu.org/gnu/bison/bison-${BISON_VERSION}.tar.xz" \
    | tar xJ --no-same-owner --strip-components=1 -C "${__SOURCE_DIR__}/bison" && \
  cd "${__SOURCE_DIR__}/bison/_build" && \
  ../configure \
    --quiet \
    --enable-silent-rules && \
  make > /dev/null && \
  make install-strip > /dev/null && \
  install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "${__PREFIX__}/licenses/bison" && \
  (cd .. && find ./ -type f -a \( -name '*LICENSE*' -o -name '*COPYING*' \) -exec cp --parents {} "${__PREFIX__}/licenses/bison" ';') && \
  cd - && \
  rm -rf "${__SOURCE_DIR__}/bison" && \
# patch
  echo '=== installing patch ===' && \
  install --directory "${__SOURCE_DIR__}/patch/_build" && \
  curl --silent --location --retry 3 "https://ftp.gnu.org/gnu/patch/patch-${PATCH_VERSION}.tar.xz" \
    | tar xJ --no-same-owner --strip-components=1 -C "${__SOURCE_DIR__}/patch" && \
  cd "${__SOURCE_DIR__}/patch/_build" && \
  ../configure \
    --quiet \
    --disable-silent-rules && \
  make > /dev/null && \
  make install-strip > /dev/null && \
  install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "${__PREFIX__}/licenses/patch" && \
  (cd .. && find ./ -type f -a \( -name '*LICENSE*' -o -name '*COPYING*' \) -exec cp --parents {} "${__PREFIX__}/licenses/patch" ';') && \
  cd - && \
  rm -rf "${__SOURCE_DIR__}/patch" && \
# libtool
  echo '=== installing libtool ===' && \
  install --directory "${__SOURCE_DIR__}/libtool/_build" && \
  curl --silent --location --retry 3 "https://ftp.gnu.org/gnu/libtool/libtool-${LIBTOOL_VERSION}.tar.xz" \
    | tar xJ --no-same-owner --strip-components=1 -C "${__SOURCE_DIR__}/libtool" && \
  cd "${__SOURCE_DIR__}/libtool/_build" && \
  ../configure \
    --quiet \
    --with-sysroot \
    --enable-ltdl-install && \
  make > /dev/null && \
  make install-strip > /dev/null && \
  install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "${__PREFIX__}/licenses/libtool" && \
  (cd .. && find ./ -type f -a \( -name '*LICENSE*' -o -name '*COPYING*' \) -exec cp --parents {} "${__PREFIX__}/licenses/libtool" ';') && \
  cd - && \
  rm -rf "${__SOURCE_DIR__}/libtool" && \
# cleanup
  echo '=== cleaning up ===' && \
  rm -rf "${__BUILD_DIR__}${__PREFIX__}/_delete_" && \
  find "${__BUILD_DIR__}${__PREFIX__}/lib64" -type f -name '*.la' -delete && \
# stripping
  echo '=== stripping libraries and binaries ===' && \
  find "${__BUILD_DIR__}${__PREFIX__}/lib64" -type f -name '*.a' -exec strip --strip-debug {} ';' && \
  find "${__BUILD_DIR__}${__PREFIX__}/lib64" -type f -name '*.so*' -exec strip --strip-unneeded {} ';' && \
  find "${__BUILD_DIR__}${__PREFIX__}/bin" -type f -not -links +1 -exec strip --strip-all {} ';' && \
# dependencies
  echo '=== instaling dependencies ===' && \
  yum --assumeyes --quiet history undo last && \
  yum --assumeyes --quiet install \
    bzip2 \
    diffutils \
    findutils \
    tar && \
# build env
  echo '=== setting build env ===' && \
  unset CONFIG_SITE && \
  export CFLAGS="-O3 -s -w -pipe -m64 -mtune=generic" && \
# busybox
  echo '=== installing busybox ===' && \
  install --directory "${__SOURCE_DIR__}/busybox/_build" && \
  curl --silent --location --retry 3 "https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2" \
    | tar xj --no-same-owner --strip-components=1 -C "${__SOURCE_DIR__}/busybox" && \
  cd "${__SOURCE_DIR__}/busybox/_build" && \
  curl --silent --location --retry 3 "https://708350.bugs.gentoo.org/attachment.cgi?id=611780&action=diff&format=raw&headers=1" \
    | patch --silent --backup --unified --strip=1 --directory='../' && \
  make KBUILD_SRC="../" --makefile="../Makefile" defconfig > /dev/null && \
  sed -i.orig \
    -e 's/.*CONFIG_STATIC.*/CONFIG_STATIC=y/' \
    -e 's/.*CONFIG_LINUXRC.*/CONFIG_LINUXRC=n/' \
    -e 's/.*CONFIG_INSTALL_APPLET_SYMLINKS.*/CONFIG_INSTALL_APPLET_SYMLINKS=n/' \
    -e 's/.*CONFIG_INSTALL_APPLET_HARDLINKS.*/CONFIG_INSTALL_APPLET_HARDLINKS=y/' \
    -e 's/.*CONFIG_PREFIX.*/CONFIG_PREFIX="${__BUILD_DIR__}"/' \
    ./.config && \
  make KBUILD_SRC="../" --makefile="../Makefile" oldconfig > /dev/null && \
  make busybox > /dev/null && \
  make install > /dev/null && \
  install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "${__BUILD_DIR__}/licenses/busybox" && \
  (cd .. && find ./ -type f -a \( -name '*LICENSE*' -o -name '*COPYING*' \) -exec cp --parents {} "${__BUILD_DIR__}/licenses/busybox" ';') && \
  cd - && \
  rm -rf "${__SOURCE_DIR__}/busybox" && \
# licenses
  echo '=== project licenses ===' && \
  install --owner=${__USER__} --group=${__USER__} --mode=0644 --target-directory="${__BUILD_DIR__}${__PREFIX__}/licenses" "${__WORK_DIR__}/LICENSE" && \
  (cd "${__BUILD_DIR__}${__PREFIX__}/licenses" && for project in *; do if [ ! -e "${__BUILD_DIR__}/licenses/${project}" ]; then ln --symbolic "..${__PREFIX__}/licenses/${project}" "${__BUILD_DIR__}/licenses/${project}"; fi; done) && \
# system settings
  echo '=== system settings ===' && \
  install --directory --owner=${__USER__} --group=${__USER__} --mode=0755 "${__BUILD_DIR__}/run/systemd" && \
  echo 'docker' > "${__BUILD_DIR__}/run/systemd/container" && \
# done
  echo '=== all done! ==='



FROM scratch

ARG __PREFIX__
ARG __WORK_DIR__

LABEL \
  maintainer="Frederico Martins <https://hub.docker.com/u/fscm/>" \
  vendor="fscm" \
  cmd="docker container run --interactive --rm --tty fscm/toolchain" \
  params="--volume ./:${__WORK_DIR__}:rw"

COPY --from=build "/build" "/"

VOLUME ["${__WORK_DIR__}"]

WORKDIR "${__WORK_DIR__}"

ENV \
  LANG="C.utf8" \
  LC_ALL="C.utf8" \
  PATH="${__PREFIX__}/bin:${PATH}"

CMD ["/usr/bin/sh"]
