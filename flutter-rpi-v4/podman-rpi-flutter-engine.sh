#!/usr/bin/env bash

# MUST EXISTS subfolders: sdk/engine sdk/sysroot - see
wget https://ftp.gnu.org/gnu/binutils/binutils-2.35.tar.gz
tar -zxf binutils-2.35.tar.gz
rm binutils-2.35.tar.gz
mv binutils-2.35 $PWD/sdk/

wget https://github.com/llvm/llvm-project/archive/llvmorg-11.0.0-rc2.tar.gz
tar -zxf llvmorg-11.0.0-rc2.tar.gz
rm llvmorg-11.0.0-rc2.tar.gz
mv llvm-project-llvmorg-11.0.0-rc2 $PWD/sdk/

podman run --rm --mount type=bind,src=/$PWD/sdk,target=/sdk debian:stretch-slim /bin/sh -c '
  export DEBIAN_FRONTEND=noninteractive \
  && export TZ=Asia/Yekaterinburg \
  && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
  && echo $TZ > /etc/timezone \
  && export TERM=dumb \
  && apt-get update \
  && apt-get install -yq --no-install-recommends \
  dialog qemu-user-static \
  flex bison texinfo \
  build-essential cmake git python3-dev libncurses5-dev libxml2-dev \
  vim libedit-dev swig doxygen graphviz xz-utils ninja-build ssh \
  && dpkg --add-architecture armhf \
  && apt-get update \
  && apt-get install -yq --no-install-recommends crossbuild-essential-armhf libpython3-dev:armhf \
  libncurses5-dev:armhf libxml2-dev:armhf libedit-dev:armhf \
  && rm -rf /var/lib/apt/lists/* \
  && export LLVM_SRC=/sdk/llvm-project-llvmorg-11.0.0-rc2/ \
  && export BINUTILS_SRC=/sdk/binutils-2.35/ \
  && export LLVM_SRC_BUILD=/root/llvm_build \
  && export LLVM_LIBCXXABI_BUILD=/root/llvm_libcxxabi_build \
  && export LLVM_LIBCXX_BUILD=/root/llvm_libcxx_build \
  && export INSTALL_PATH=/sdk/toolchain \
  && mkdir $LLVM_SRC_BUILD && cd $LLVM_SRC_BUILD && cmake -DLLVM_ENABLE_PROJECTS=clang -G Ninja -DCMAKE_BUILD_TYPE=Release -DLLVM_BUILD_DOCS=OFF -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DCMAKE_CROSSCOMPILING=True -DLLVM_DEFAULT_TARGET_TRIPLE=arm-linux-gnueabihf -DLLVM_TARGET_ARCH=ARM -DLLVM_TARGETS_TO_BUILD=ARM $LLVM_SRC/llvm \
  && ninja \
  && ninja install \
  && cp -R $BINUTILS_SRC /root/ && cd /root/binutils-2.35/ \
  && ./configure --prefix=$INSTALL_PATH --enable-gold --enable-ld --target=arm-linux-gnueabihf \
  && make \
  && make install \
  && mkdir $LLVM_LIBCXXABI_BUILD && cd $LLVM_LIBCXXABI_BUILD \
    && cmake -G Ninja \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH \
    -DCMAKE_C_COMPILER=$INSTALL_PATH/bin/clang \
    -DCMAKE_CXX_COMPILER=$INSTALL_PATH/bin/clang++ \
    -DCMAKE_CROSSCOMPILING=True \
    -DLIBCXX_ENABLE_SHARED=FALSE \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SYSTEM_NAME=Linux \
    -DCMAKE_SYSTEM_PROCESSOR=ARM \
    -DLLVM_TARGETS_TO_BUILD=ARM \
    -DLIBCXXABI_ENABLE_EXCEPTIONS=False \
    $LLVM_SRC/libcxxabi \
    && ninja \
    && ninja install \
  && mkdir $LLVM_LIBCXX_BUILD && cd $LLVM_LIBCXX_BUILD \
    && cmake -G Ninja \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH \
    -DCMAKE_C_COMPILER=$INSTALL_PATH/bin/clang \
    -DCMAKE_CXX_COMPILER=$INSTALL_PATH/bin/clang++ \
    -DCMAKE_CROSSCOMPILING=True \
    -DLIBCXX_ENABLE_SHARED=False \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SYSTEM_NAME=Linux \
    -DCMAKE_SYSTEM_PROCESSOR=ARM \
    -DLLVM_TARGETS_TO_BUILD=ARM \
    -DLIBCXX_ENABLE_EXCEPTIONS=False \
    -DLIBCXX_ENABLE_RTTI=False \
    -DLIBCXX_CXX_ABI=libcxxabi \
    -DLIBCXX_CXX_ABI_INCLUDE_PATHS=$LLVM_SRC/libcxxabi/include \
    -DLIBCXX_CXX_ABI_LIBRARY_PATH=$INSTALL_PATH/lib \
    -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=True \
    $LLVM_SRC/libcxx \
    && ninja \
    && ninja install'

podman run --rm --mount type=bind,src=/$PWD/sdk,target=/sdk ubuntu:bionic /bin/sh -c '
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
  && cd /sdk/engine/src/build \
  && sudo ./install-build-deps-android.sh --no-arm \
  && echo N | ./install-build-deps.sh --no-arm \
  && cd /sdk/engine/src/flutter/build \
  && sudo ./install-build-deps-linux-desktop.sh \
  && export PKG_CONFIG_PATH=/sdk/sysroot/usr/lib/arm-linux-gnueabihf/pkgconfig/:/sdk/sysroot/usr/share/pkgconfig/ \
  && cd /sdk/engine/src \
  && ./flutter/tools/gn \
    --target-sysroot /sdk/sysroot \
    --target-toolchain /sdk/toolchain \
    --target-triple arm-linux-gnueabihf \
    --linux-cpu arm \
    --runtime-mode debug \
    --embedder-for-target \
    --no-lto \
    --target-os linux \
    --arm-float-abi hard \
  && cd out/ \
  && ninja -C linux_debug_arm \
  && cd linux_debug_arm/ \
  && ls -la \
  && cp flutter_embedder.h /sdk \
  && cp libflutter_engine.so /sdk \
  && cp icudtl.dat /sdk \
  && rm -rf /sdk/engine/src/out/*'
