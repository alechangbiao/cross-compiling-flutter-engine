#!/usr/bin/env bash

# STEP 1 - create image
# flex bison texinfo vim

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
  && apt install -yq --no-install-recommends gcc-10 g++-10 make \
  wget curl unzip git python3-distutils libssl-dev \
  libc6 libc6-dev libstdc++6 x11proto-dev libgtk-3-dev pkg-config libblkid-dev libfreetype6 libfreetype6-dev libpng16-16 libpng-dev \
  && mkdir /build' \
  && buildah commit ${container} ${IMG_NAME} || buildah rm ${container}

# STEP 2 - start container
podman run -ti --name ubt-flutter-engine \
  --mount type=bind,src=/$PWD/sdk,target=/sdk/ \
  --env INSTALL_PATH=/sdk/toolchain \
  --env SYSROOT_PATH=/sdk/sysroot \
  localhost/ubt-bionic-clang-arm64-img /bin/bash

# STEP 3 - all next steps inside container
cd /root \
&& git clone --depth 1 -b llvmorg-11.0.0 https://github.com/llvm/llvm-project.git \
&& git clone --depth 1 -b v3.18.4 https://github.com/Kitware/CMake.git \
&& git clone --depth 1 -b v1.10.1 https://github.com/ninja-build/ninja.git

export CC=gcc-10 \
&& export CXX=g++-10 \
&& cd CMake && ./bootstrap && make && make install \
&& cd ../ninja \
&& cmake -Bbuild-cmake -H. && cmake --build build-cmake

cp build-cmake/ninja /usr/bin/
mkdir /sdk/toolchain

cd /build
rm -rf ./*
CC=gcc-10 CXX=g++-10 cmake /root/llvm-project/llvm \
  -DLLVM_ENABLE_PROJECTS="lld;clang" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_INCLUDE_BENCHMARKS=OFF \
  -DLLVM_INCLUDE_EXAMPLES=OFF \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH \
  -DLLVM_DEFAULT_TARGET_TRIPLE=aarch64-linux-gnueabihf \
  -DLLVM_TARGET_ARCH=AArch64 \
  -DLLVM_TARGETS_TO_BUILD=AArch64 \
  && ninja install
#

rm -rf ./* \
&& cmake -G Ninja \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH \
  -DCMAKE_C_COMPILER=$INSTALL_PATH/bin/clang \
  -DCMAKE_CXX_COMPILER=$INSTALL_PATH/bin/clang++ \
  -DCMAKE_C_FLAGS="-fuse-ld=lld" \
  -DCMAKE_CXX_FLAGS="-fuse-ld=lld" \
  -DCMAKE_SYSROOT=$SYSROOT_PATH \
  -DCMAKE_CROSSCOMPILING=True \
  -DLIBCXX_ENABLE_SHARED=FALSE \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_SYSTEM_NAME=Linux \
  -DCMAKE_SYSTEM_PROCESSOR=AArch64 \
  -DLLVM_TARGETS_TO_BUILD=AArch64 \
  -DLIBCXXABI_ENABLE_EXCEPTIONS=False \
  /root/llvm-project/libcxxabi \
  && ninja install
#
rm -rf ./*
cmake -G Ninja \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH \
  -DCMAKE_C_COMPILER=$INSTALL_PATH/bin/clang \
  -DCMAKE_CXX_COMPILER=$INSTALL_PATH/bin/clang++ \
  -DCMAKE_C_FLAGS="-fuse-ld=lld" \
  -DCMAKE_CXX_FLAGS="-fuse-ld=lld" \
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
  -DLIBCXX_CXX_ABI_INCLUDE_PATHS=/root/llvm-project/libcxxabi/include \
  -DLIBCXX_CXX_ABI_LIBRARY_PATH=$INSTALL_PATH/lib \
  -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=True \
  /root/llvm-project/libcxx \
  && ninja install

cp /root/llvm-project/libcxxabi/include/__cxxabi_config.h $INSTALL_PATH/include/c++/v1/ \
&& cp /root/llvm-project/libcxxabi/include/cxxabi.h $INSTALL_PATH/include/c++/v1/

# configure linker for use native llvm-lld
cd $INSTALL_PATH/bin/
ln -s llvm-ar aarch64-linux-gnueabihf-ar
ln -s llvm-as aarch64-linux-gnueabihf-as
ln -s lld ld
ln -s lld aarch64-linux-gnueabihf-ld
ln -s lld aarch64-linux-gnueabihf-lld
ln -s llvm-nm aarch64-linux-gnueabihf-nm
ln -s llvm-objcopy aarch64-linux-gnueabihf-objcopy
ln -s llvm-objdump aarch64-linux-gnueabihf-objdump
ln -s llvm-ranlib aarch64-linux-gnueabihf-ranlib
ln -s llvm-readelf aarch64-linux-gnueabihf-readelf
ln -s llvm-strip aarch64-linux-gnueabihf-strip

# STEP 4 - you are ready for cross-compile the flutter engine
# it's need at this step
export PKG_CONFIG_PATH=/sdk/sysroot/usr/lib/aarch64-linux-gnu/pkgconfig/:/sdk/sysroot/usr/share/pkgconfig/ \
&& cd /sdk/engine/src || exit 0

apt-get update && apt install python-minimal -yq

rm -rf out/* \
&& ./flutter/tools/gn \
  --target-sysroot /sdk/sysroot \
  --target-toolchain /sdk/toolchain \
  --target-triple aarch64-linux-gnueabihf \
  --linux-cpu arm64 \
  --runtime-mode release \
  --target-os linux \
  --no-build-glfw-shell

ninja -C out/linux_release_arm64/

# STEP 5 - get flutter for x86-64
# https://github.com/flutter/flutter/wiki/Flutter-build-release-channels
# https://github.com/flutter/flutter/wiki/Flutter-Installation-Bundles

# run flutter doctor -v  on the host
#Flutter (Channel dev, 1.23.0-18.0.pre, on Linux, locale ru_RU.UTF-8)
#    • Flutter version 1.23.0-18.0.pre at /home/eugen/jetBrains/sdk/flutter
#    • Framework revision 37ebe3d82a (6 дней назад), 2020-10-13 10:52:23 -0700
#    • Engine revision 6634406889
#    • Dart version 2.11.0 (build 2.11.0-213.0.dev)

# you should know Flutter version tag - 1.23.0-18.0.pre and corresponding dart-sdk version tag - 2.11.0-213.0.dev

# view last tags https://github.com/flutter/flutter/tags
# git clone --depth 1 -b 1.23.0-18.0.pre https://github.com/flutter/flutter.git
# download flutter artifacts, it will finish with error, because downloaded dart-sdk for x86-64, it's normal

# https://flutter.dev/docs/development/tools/sdk/releases?tab=linux
# get latest flutter dev release

cd /root
wget -qO- https://storage.googleapis.com/flutter_infra/releases/dev/linux/flutter_linux_1.23.0-18.0.pre-dev.tar.xz | tar xJf -
# to specify directory
# wget -qO- your_link_here | tar xvz - -C /target/directory

export PATH=$PATH:/root/flutter/bin
# reset PKG_CONFIG_PATH
export PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig/:/usr/share/pkgconfig/
# https://flutter.dev/desktop
apt update && apt install -yq clang libblkid-dev

flutter doctor -v \
&& flutter config --enable-linux-desktop

flutter create myapp \
&& cd myapp \
&& flutter create . \
&& flutter build linux --release

# STEP 6 - configure flutter for aarch64

# https://dart.dev/tools/sdk/archive find correct dart-sdk tag and download bundle for arm64 platform
wget -q -O tmp.zip https://storage.googleapis.com/dart-archive/channels/dev/release/2.11.0-213.0.dev/sdk/dartsdk-linux-arm64-release.zip &&  unzip -q tmp.zip && rm tmp.zip

rm -rf flutter/bin/cache/dart-sdk/*
cp -R dart-sdk/* flutter/bin/cache/dart-sdk/

rm -rf ~/flutter/bin/cache/artifacts/engine/common/flutter_patched_sdk/* \
&& rm -rf ~/flutter/bin/cache/artifacts/engine/common/flutter_patched_sdk_product/* \
&& rm -rf ~/flutter/bin/cache/artifacts/engine/linux-x64/* \
&& rm -rf ~/flutter/bin/cache/artifacts/engine/linux-x64-release/*

cp -R /sdk/engine/src/out/linux_release_arm64/flutter_patched_sdk/* ~/flutter/bin/cache/artifacts/engine/common/flutter_patched_sdk/
cp -R /sdk/engine/src/out/linux_release_arm64/flutter_patched_sdk/* ~/flutter/bin/cache/artifacts/engine/common/flutter_patched_sdk_product/

cp -R /sdk/engine/src/out/linux_release_arm64/gen/const_finder.dart.snapshot ~/flutter/bin/cache/artifacts/engine/linux-x64/
cp -R /sdk/engine/src/out/linux_release_arm64/flutter_linux ~/flutter/bin/cache/artifacts/engine/linux-x64/
cp -R /sdk/engine/src/out/linux_release_arm64/flutter_tester ~/flutter/bin/cache/artifacts/engine/linux-x64/
cp -R /sdk/engine/src/out/linux_release_arm64/font-subset ~/flutter/bin/cache/artifacts/engine/linux-x64/
cp -R /sdk/engine/src/out/linux_release_arm64/gen/frontend_server.dart.snapshot ~/flutter/bin/cache/artifacts/engine/linux-x64/
cp -R /sdk/engine/src/out/linux_release_arm64/icudtl.dat ~/flutter/bin/cache/artifacts/engine/linux-x64/
cp -R /sdk/engine/src/out/linux_release_arm64/gen/flutter/lib/snapshot/isolate_snapshot.bin ~/flutter/bin/cache/artifacts/engine/linux-x64/
cp -R /sdk/engine/src/out/linux_release_arm64/libflutter_linux_gtk.so ~/flutter/bin/cache/artifacts/engine/linux-x64/
cp -R /sdk/engine/src/out/linux_release_arm64/gen/flutter/lib/snapshot/vm_isolate_snapshot.bin ~/flutter/bin/cache/artifacts/engine/linux-x64/

cp -R /sdk/engine/src/out/linux_release_arm64/flutter_linux ~/flutter/bin/cache/artifacts/engine/linux-x64-release/
cp -R /sdk/engine/src/out/linux_release_arm64/dart-sdk/bin/utils/gen_snapshot ~/flutter/bin/cache/artifacts/engine/linux-x64-release/
cp -R /sdk/engine/src/out/linux_release_arm64/libflutter_linux_gtk.so ~/flutter/bin/cache/artifacts/engine/linux-x64-release/

cp -R flutter /sdk/