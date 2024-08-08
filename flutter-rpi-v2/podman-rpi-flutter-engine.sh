#!/usr/bin/env bash

# HOW TO START:
# TMPDIR=/PATH_TO_TMP_DIR buildah unshare ./podman-rpi-flutter-engine.sh

set -e

container=$(buildah from ubuntu:bionic)

buildah run ${container} sh <<EOM
  export DEBIAN_FRONTEND=noninteractive \
  && export TZ=Asia/Yekaterinburg \
  && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
  && echo $TZ > /etc/timezone \
  && export TERM=dumb \
  && apt-get update \
  && apt-get install -yq --no-install-recommends \
  lsb-core lsb-release sudo nano vim wget \
  dialog qemu-user-static \
  bison cdbs curl devscripts \
  dpkg-dev elfutils fakeroot \
  flex g++ git-core git-svn \
  gperf libasound2 libasound2-dev libatk1.0-0 \
  libbrlapi-dev libbrlapi0.6 libbz2-dev libc6 \
  libcairo2 libcairo2-dev libcap-dev libcap2 \
  libcups2 libcups2-dev libcurl4-gnutls-dev \
  libdrm-dev libelf-dev libexif-dev libexif12 \
  libexpat1 libfontconfig1 libfreetype6 libgbm-dev \
  libgconf2-dev libgl1-mesa-dev libgles2-mesa-dev \
  libglib2.0-0 libglib2.0-dev libglu1-mesa-dev \
  libgnome-keyring-dev libgnome-keyring0 libgtk2.0-0 \
  libgtk2.0-dev libjpeg-dev libkrb5-dev libnspr4 \
  libnspr4-dev libnss3 libnss3-dev libpam0g libpam0g-dev \
  libpango1.0-0 libpci-dev libpci3 libpcre3 libpixman-1-0 \
  libpng16-16 libpulse-dev libsctp-dev libspeechd-dev \
  libspeechd2 libsqlite3-0 libsqlite3-dev libssl-dev \
  libstdc++6 libudev-dev libudev1 libwww-perl libx11-6 \
  libxau6 libxcb1 libxcomposite1 libxcursor1 libxdamage1 \
  libxdmcp6 libxext6 libxfixes3 libxi6 libxinerama1 libxrandr2 \
  libxrender1 libxslt1-dev libxss-dev libxt-dev libxtst-dev \
  libxtst6 mesa-common-dev patch perl pkg-config python \
  python-cherrypy3 python-crypto python-dev python-numpy \
  python-opencv python-openssl python-psutil python-yaml \
  rpm ruby subversion wdiff zip zlib1g \
  build-essential cmake git python3-dev libncurses5-dev libxml2-dev \
  libedit-dev swig doxygen graphviz xz-utils ninja-build ssh \
  openjdk-8-jre openjdk-8-jdk \
  libgtk-3-dev \
  && sudo update-java-alternatives -s java-1.8.0-openjdk-amd64 \
  && apt-get install -yq --no-install-recommends ant \
  && mkdir "/src"
EOM

mntPoint=$(buildah mount ${container})
echo "mounted container"
cp -R $PWD/src/engine ${mntPoint}/src/
cp -R $PWD/src/sysroot ${mntPoint}/src/
cp -R $PWD/src/cross_armhf_clang_11.0.0-rc2 ${mntPoint}/src/
cp -R $PWD/compile-flutter-engine.sh ${mntPoint}/src/engine/src

echo "compile engine"
buildah run ${container} sh <<EOM
  set -eux; \
  cd /src/engine/src/build \
  && sudo ./install-build-deps-android.sh --no-arm \
  && cd /src/engine/src/flutter/build \
  && sudo ./install-build-deps-linux-desktop.sh \
  && export PKG_CONFIG_PATH=/src/sysroot/usr/lib/arm-linux-gnueabihf/pkgconfig/:/src/sysroot/usr/share/pkgconfig/ \
  && cd /src/engine/src \
  && ./compile-flutter-engine.sh \
  && cd out/ \
  && find . -mindepth 1 -maxdepth 1 -type d | xargs -n 1 sh -c 'ninja -C linux_debug_arm || exit 255' \
  && cd linux_debug_arm/ \
  && ls -la \
  && cp flutter_embedder.h libflutter_engine.so icudtl.dat $PWD/compile-flutter-engine.sh
EOM

cp ${mntPoint}/src/engine/src/out/linux_debug_arm/flutter_embedder.h $PWD/src
cp ${mntPoint}/src/engine/src/out/linux_debug_arm/libflutter_engine.so $PWD/src
cp ${mntPoint}/src/engine/src/out/linux_debug_arm/icudtl.dat $PWD/src
buildah unmount ${container}

buildah rm ${container}
# && ./install-build-deps.sh --no-arm \
# - packages installed above or need to automatic NO for question about install debug symbols

# buildah commit ${container} flutter-ubuntu-dev

#
#podman run --rm --mount type=bind,src=/$PWD/src,target=/src localhost/flutter-ubuntu-dev <<EOM
#  export PKG_CONFIG_PATH=/src/sysroot/usr/lib/arm-linux-gnueabihf/pkgconfig/:/src/sysroot/usr/share/pkgconfig/ \
#  && cd /src/engine/src \
#  && ./compile-flutter-engine.sh \
#  && cd out/ \
#  && find . -mindepth 1 -maxdepth 1 -type d | xargs -n 1 sh -c 'ninja -C $0 || exit 255' \
#  && cp flutter_embedder.h libflutter_engine.so icudtl.dat /src/
#EOM
