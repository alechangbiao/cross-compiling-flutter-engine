#!/usr/bin/env bash

# https://github.com/multiarch/qemu-user-static/blob/master/README.md
# sudo apt install qemu-arch-extra
# sudo podman run --rm --privileged multiarch/qemu-user-static --reset -p yes


# STEP 1
podman run -ti --mount type=bind,src=/$PWD/sdk,target=/sdk multiarch/ubuntu-core:arm64-bionic /bin/bash
# if you get error - run
# $ sudo podman run --rm --privileged multiarch/qemu-user-static --reset -p yes

# STEP 2 - inside container
apt update \
&& apt install -yq --no-install-recommends \
libblkid-dev libc6 libc6-dev libstdc++6 x11proto-dev libgtk-3-dev \
libfreetype6 libfreetype6-dev libpng16-16 libpng-dev \
git make libssl-dev file pkg-config wget curl unzip

# https://flutter.dev/desktop
# if you would build flutter on rpi:
# apt install -yq --no-install-recommends clang cmake ninja-build pkg-config

# STEP 3 - prepare sysroot src
mkdir /sdk/sysroot

export SYSROOT_PATH=/sdk/sysroot \
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
cd /sdk/
apt-get update && apt install python-minimal -yq
# or you can set python3 inside sysroot-relativelinks.py file
./sysroot-relativelinks.py sysroot

# STEP 4 - go to script 2 and get flutter

# STEP 5 - return and test flutter
cp -R /sdk/root/flutter /root/
cp -R /sdk/root/.config /root/
cp -R /sdk/root/.flutter /root/
ls -la /root/flutter
# flutter .config .flutter

export PATH=$PATH:/root/flutter/bin
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

apt update && apt install -yq clang cmake ninja-build pkg-config libgtk-3-dev libblkid-dev

flutter create myapp \
&& cd myapp \
&& flutter create .

flutter build -v linux --release
