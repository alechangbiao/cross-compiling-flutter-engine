#!/usr/bin/env bash

# STEP 1
podman run -ti --mount type=bind,src=/$PWD/sdk,target=/sdk multiarch/ubuntu-core:arm64-bionic /bin/bash

# STEP 2 - inside container
apt update \
&& apt install -yq --no-install-recommends \
clang cmake ninja-build pkg-config \
git-core wget libblkid-dev \
libc6 libc6-dev libstdc++6 x11proto-dev libgtk-3-dev \
libfreetype6 libfreetype6-dev libpng16-16 libpng-dev

# https://flutter.dev/desktop
# if you would build flutter on rpi:
# apt install -yq --no-install-recommends clang cmake ninja-build pkg-config

# STEP 3 - prepare sysroot src
export SYSROOT_PATH=/sdk/sysroot-arm64-ubt18 \
&& rm -rf $SYSROOT_PATH/* \
&& mkdir -p $SYSROOT_PATH/lib \
&& mkdir -p $SYSROOT_PATH/usr \
&& mkdir -p $SYSROOT_PATH/usr/lib \
&& mkdir -p $SYSROOT_PATH/usr/include \
&& mkdir -p $SYSROOT_PATH/usr/share/pkgconfig \
&& cp -R /usr/lib/* $SYSROOT_PATH/usr/lib/ \
&& cp -R /usr/include/* $SYSROOT_PATH/usr/include/ \
&& cp -R /usr/share/pkgconfig/* $SYSROOT_PATH/usr/share/pkgconfig/ \
&& cp -R /lib/* $SYSROOT_PATH/lib/
# only if cross-compile error occured
# ln -s $SYSROOT_PATH/usr/lib/aarch64-linux-gnu/libstdc++.so.6 $SYSROOT_PATH/usr/lib/libstdc++.so
#

# Start a new ternimal
# go to project folder NOT THE CONTAINER
cd ~/developer/flutter-engine/sdk/
./sysroot-relativelinks.py sysroot-arm64-ubt18

# STEP 4 - prepare flutter
mkdir /root/flutter \
&& cd /root/ \
&& cp -R /sdk/flutter/* /root/flutter/ \
&& export PATH=$PATH:/root/flutter/bin/ \
&& flutter doctor -v \
&& flutter config --enable-linux-desktop \
&& flutter create myapp \
&& cd myapp \
&& flutter create . \
&& rm -rf ~/flutter/bin/cache/artifacts/engine/common/flutter_patched_sdk/* \
&& rm -rf ~/flutter/bin/cache/artifacts/engine/common/flutter_patched_sdk_product/* \
&& rm ~/flutter/bin/cache/artifacts/engine/linux-x64/const_finder.dart.snapshot \
&& rm ~/flutter/bin/cache/artifacts/engine/linux-x64/flutter_linux/* \
&& rm ~/flutter/bin/cache/artifacts/engine/linux-x64/flutter_tester \
&& rm ~/flutter/bin/cache/artifacts/engine/linux-x64/font-subset \
&& rm ~/flutter/bin/cache/artifacts/engine/linux-x64/icudtl.dat \
&& rm ~/flutter/bin/cache/artifacts/engine/linux-x64/isolate_snapshot.bin \
&& rm ~/flutter/bin/cache/artifacts/engine/linux-x64/frontend_server.dart.snapshot \
&& rm ~/flutter/bin/cache/artifacts/engine/linux-x64/libflutter_linux_gtk.so \
&& rm ~/flutter/bin/cache/artifacts/engine/linux-x64/vm_isolate_snapshot.bin \
&& rm -rf ~/flutter/bin/cache/artifacts/engine/linux-x64-release/flutter_linux/* \
&& rm -rf ~/flutter/bin/cache/artifacts/engine/linux-x64-release/gen_snapshot \
&& rm -rf ~/flutter/bin/cache/artifacts/engine/linux-x64-release/libflutter_linux_gtk.so

# STEP 5 - after cross-compilation the flutter engine - switch to script 2-4 and return
cp -R /sdk/engine/src/out/linux_release_arm64/flutter_patched_sdk/* ~/flutter/bin/cache/artifacts/engine/common/flutter_patched_sdk/ \
&& cp -R /sdk/engine/src/out/linux_release_arm64/flutter_patched_sdk/* ~/flutter/bin/cache/artifacts/engine/common/flutter_patched_sdk_product/ \
&& cp /sdk/engine/src/out/linux_release_arm64/gen/const_finder.dart.snapshot ~/flutter/bin/cache/artifacts/engine/linux-x64/ \
&& cp /sdk/engine/src/out/linux_release_arm64/flutter_linux/* ~/flutter/bin/cache/artifacts/engine/linux-x64/flutter_linux/ \
&& cp /sdk/engine/src/out/linux_release_arm64/flutter_tester ~/flutter/bin/cache/artifacts/engine/linux-x64/ \
&& cp /sdk/engine/src/out/linux_release_arm64/font-subset ~/flutter/bin/cache/artifacts/engine/linux-x64/ \
&& cp /sdk/engine/src/out/linux_release_arm64/gen/frontend_server.dart.snapshot ~/flutter/bin/cache/artifacts/engine/linux-x64 \
&& cp /sdk/engine/src/out/linux_release_arm64/icudtl.dat ~/flutter/bin/cache/artifacts/engine/linux-x64/ \
&& cp /sdk/engine/src/out/linux_release_arm64/gen/flutter/lib/snapshot/isolate_snapshot.bin ~/flutter/bin/cache/artifacts/engine/linux-x64/ \
&& cp /sdk/engine/src/out/linux_release_arm64/libflutter_linux_gtk.so ~/flutter/bin/cache/artifacts/engine/linux-x64 \
&& cp /sdk/engine/src/out/linux_release_arm64/gen/flutter/lib/snapshot/vm_isolate_snapshot.bin ~/flutter/bin/cache/artifacts/engine/linux-x64/ \
&& cp /sdk/engine/src/out/linux_release_arm64/flutter_linux/* ~/flutter/bin/cache/artifacts/engine/linux-x64-release/flutter_linux/ \
&& cp -R /sdk/engine/src/out/linux_release_arm64/dart-sdk/bin/utils/gen_snapshot ~/flutter/bin/cache/artifacts/engine/linux-x64-release/ \
&& cp -R /sdk/engine/src/out/linux_release_arm64/libflutter_linux_gtk.so ~/flutter/bin/cache/artifacts/engine/linux-x64-release/
