#!/usr/bin/env bash

# STEP 1 - create image
IMG_NAME=ubt-bionic-clang-arm64-img \
&& container=$(buildah from ubuntu:bionic) \
&& buildah run ${container} /bin/sh -c '
  export DEBIAN_FRONTEND=noninteractive \
  && export TZ=Asia/Yekaterinburg \
  && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
  && echo $TZ > /etc/timezone \
  && export TERM=dumb \
  && apt-get update \
  && apt-get install -yq --no-install-recommends software-properties-common \
  && echo | add-apt-repository ppa:ubuntu-toolchain-r/test \
  && apt-get update \
  && apt install gcc-10 g++-10 -yq --no-install-recommends \
  && apt-get install -yq --no-install-recommends \
  build-essential flex bison texinfo vim \
  git cmake ninja-build python3-distutils \
  libc6 libc6-dev libstdc++6 x11proto-dev libgtk-3-dev libfreetype6 libfreetype6-dev libpng16-16 libpng-dev \
  && export LLVM_SRC_BUILD=/root/llvm_build \
  && export LLVM_LIBCXXABI_BUILD=/root/llvm_libcxxabi_build \
  && export LLVM_LIBCXX_BUILD=/root/llvm_libcxx_build \
  && mkdir -p $LLVM_SRC_BUILD \
  && mkdir -p $LLVM_LIBCXXABI_BUILD \
  && mkdir -p $LLVM_LIBCXX_BUILD ' \
  && buildah commit ${container} ${IMG_NAME} || buildah rm ${container}

# STEP 2 - start container
podman run -ti --name ubt-bionic-clang-arm64 \
  --mount type=bind,src=/$PWD/sdk,target=/sdk \
  --env LLVM_SRC=/sdk/llvm/ \
  --env BINUTILS_SRC=/sdk/binutils/ \
  --env LLVM_BUILD=/root/llvm_build \
  --env LLVM_LIBCXXABI_BUILD=/root/llvm_libcxxabi_build \
  --env LLVM_LIBCXX_BUILD=/root/llvm_libcxx_build \
  --env INSTALL_PATH=/sdk/toolchain-arm64-ubt18 \
  --env SYSROOT_PATH=/sdk/sysroot-arm64-ubt18 \
  localhost/ubt-bionic-clang-arm64-img /bin/bash

# STEP 3 - inside container
cd $LLVM_BUILD && CC=gcc-10 CXX=g++-10 cmake $LLVM_SRC/llvm \
  -DLLVM_ENABLE_PROJECTS="clang" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_INCLUDE_BENCHMARKS=OFF \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH \
  -DLLVM_DEFAULT_TARGET_TRIPLE=aarch64-linux-gnueabihf \
  -DLLVM_TARGET_ARCH=AArch64 \
  -DLLVM_TARGETS_TO_BUILD=AArch64 \
  && ninja install
#

cp -R $BINUTILS_SRC ~/ && cd ~/binutils \
&& ./configure --prefix=$INSTALL_PATH --enable-gold --enable-ld --target=aarch64-linux-gnueabihf \
&& make && make install
#
cd $LLVM_LIBCXXABI_BUILD && cmake -G Ninja \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH \
  -DCMAKE_C_COMPILER=$INSTALL_PATH/bin/clang \
  -DCMAKE_CXX_COMPILER=$INSTALL_PATH/bin/clang++ \
  -DCMAKE_SYSROOT=$SYSROOT_PATH \
  -DCMAKE_CROSSCOMPILING=True \
  -DLIBCXX_ENABLE_SHARED=FALSE \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_SYSTEM_NAME=Linux \
  -DCMAKE_SYSTEM_PROCESSOR=AArch64 \
  -DLLVM_TARGETS_TO_BUILD=AArch64 \
  -DLIBCXXABI_ENABLE_EXCEPTIONS=False \
  $LLVM_SRC/libcxxabi \
  && ninja install
#
cd $LLVM_LIBCXX_BUILD && cmake -G Ninja \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH \
  -DCMAKE_C_COMPILER=$INSTALL_PATH/bin/clang \
  -DCMAKE_CXX_COMPILER=$INSTALL_PATH/bin/clang++ \
  -DCMAKE_SYSROOT=$SYSROOT_PATH \
  -DCMAKE_CROSSCOMPILING=True \
  -DLIBCXX_ENABLE_SHARED=False \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_SYSTEM_NAME=Linux \
  -DCMAKE_SYSTEM_PROCESSOR=AArch64 \
  -DLLVM_TARGETS_TO_BUILD=AArch64 \
  -DLIBCXX_ENABLE_EXCEPTIONS=False \
  -DLIBCXX_ENABLE_RTTI=False \
  -DLIBCXX_CXX_ABI=libcxxabi \
  -DLIBCXX_CXX_ABI_INCLUDE_PATHS=$LLVM_SRC/libcxxabi/include \
  -DLIBCXX_CXX_ABI_LIBRARY_PATH=$INSTALL_PATH/lib \
  -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=True \
  $LLVM_SRC/libcxx \
  && ninja install

cp $LLVM_SRC/libcxxabi/include/__cxxabi_config.h $INSTALL_PATH/include/c++/v1/ \
&& cp $LLVM_SRC/libcxxabi/include/cxxabi.h $INSTALL_PATH/include/c++/v1/

# it's need at this step
apt install python-minimal -yq

# install system binulils linker for aarch64-linux-gnueabihf arch
ln -s /sdk/toolchain-arm64-ubt18/aarch64-linux-gnueabihf/bin/ar /usr/bin/aarch64-linux-gnu-ar \
&& ll /usr/bin/aarch64-linux-gnu* \
&& ln -s /sdk/toolchain-arm64-ubt18/aarch64-linux-gnueabihf/bin/as /usr/bin/aarch64-linux-gnu-as \
&& ln -s /sdk/toolchain-arm64-ubt18/aarch64-linux-gnueabihf/bin/ld /usr/bin/aarch64-linux-gnu-ld \
&& ln -s /sdk/toolchain-arm64-ubt18/aarch64-linux-gnueabihf/bin/ld.bfd /usr/bin/aarch64-linux-gnu-ld.bfd \
&& ln -s /sdk/toolchain-arm64-ubt18/aarch64-linux-gnueabihf/bin/ld.gold /usr/bin/aarch64-linux-gnu-ld.gold \
&& ln -s /sdk/toolchain-arm64-ubt18/aarch64-linux-gnueabihf/bin/nm /usr/bin/aarch64-linux-gnu-nm \
&& ln -s /sdk/toolchain-arm64-ubt18/aarch64-linux-gnueabihf/bin/objcopy /usr/bin/aarch64-linux-gnu-objcopy \
&& ln -s /sdk/toolchain-arm64-ubt18/aarch64-linux-gnueabihf/bin/objdump /usr/bin/aarch64-linux-gnu-objdump \
&& ln -s /sdk/toolchain-arm64-ubt18/aarch64-linux-gnueabihf/bin/ranlib /usr/bin/aarch64-linux-gnu-ranlib \
&& ln -s /sdk/toolchain-arm64-ubt18/aarch64-linux-gnueabihf/bin/readelf /usr/bin/aarch64-linux-gnu-readelf \
&& ln -s /sdk/toolchain-arm64-ubt18/aarch64-linux-gnueabihf/bin/strip /usr/bin/aarch64-linux-gnu-strip \
&& ll /usr/bin/aarch64-linux-gnu-* \
&& ll /sdk/toolchain-arm64-ubt18/aarch64-linux-gnueabihf/ \
&& ll /sdk/toolchain-arm64-ubt18/aarch64-linux-gnueabihf/lib/ \
&& ll /sdk/toolchain-arm64-ubt18/aarch64-linux-gnueabihf/lib/ldscripts/ \
&& ll /usr/lib/  \
&& mkdir /usr/lib/aarch64-linux-gnu \
&& ln -s /sdk/toolchain-arm64-ubt18/aarch64-linux-gnueabihf/lib /usr/lib/aarch64-linux-gnu/lib \
&& ll /usr/lib/aarch64-linux-gnu/

export PKG_CONFIG_PATH=/sdk/sysroot-arm64/usr/lib/aarch64-linux-gnu/pkgconfig/:/sdk/sysroot-arm64/usr/share/pkgconfig/ \
&& cd /sdk/engine/src || exit 0

#-------------OCT19

# STEP 4 - you are ready for cross-compile the flutter engine
rm -rf out/* \
./flutter/tools/gn \
  --target-sysroot /sdk/sysroot-arm64-ubt18/ \
  --target-toolchain /sdk/toolchain-arm64-ubt18/ \
  --target-triple aarch64-linux-gnueabihf \
  --linux-cpu arm64 \
  --runtime-mode release \
  --target-os linux

ninja -C out/linux_release_arm64/
