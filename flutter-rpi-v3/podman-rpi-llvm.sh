#!/usr/bin/env bash

# HOW TO START:
# buildah unshare ./podman-rpi-llvm.sh
#
# https://solarianprogrammer.com/2019/05/04/clang-cross-compiler-for-raspberry-pi/

set -e

wget https://ftp.gnu.org/gnu/binutils/binutils-2.35.tar.gz
tar -zxf binutils-2.35.tar.gz
rm binutils-2.35.tar.gz
mv binutils-2.35 $PWD/sdk/

wget https://github.com/llvm/llvm-project/archive/llvmorg-11.0.0-rc2.tar.gz
tar -zxf llvmorg-11.0.0-rc2.tar.gz
rm llvmorg-11.0.0-rc2.tar.gz
mv llvm-project-llvmorg-11.0.0-rc2 $PWD/sdk/

container=$(buildah from debian:stretch-slim)
buildah run ${container} sh <<EOM
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
  && mkdir "/sdk"
EOM

mntPoint=$(buildah mount ${container})
echo "container mounted"
cp -R $PWD/sdk/binutils-2.35 ${mntPoint}/sdk/
cp -R $PWD/sdk/llvm-project-llvmorg-11.0.0-rc2 ${mntPoint}/sdk/
cp $PWD/install-cross-llvm.sh ${mntPoint}/root

echo "start compilation"
buildah run ${container} sh <<EOM
  set -eux; \
  cd /root && ./install-cross-llvm.sh \
  && cp /sdk/llvm-project-llvmorg-11.0.0-rc2/libcxxabi/include/cxxabi.h /usr/local/cross_armhf_clang_11.0.0-rc2/include/c++/v1/ \
  && cp /sdk/llvm-project-llvmorg-11.0.0-rc2/libcxxabi/include/__cxxabi_config.h /usr/local/cross_armhf_clang_11.0.0-rc2/include/c++/v1/
EOM

cp -R ${mntPoint}/usr/local/cross_armhf_clang_11.0.0-rc2 $PWD/sdk
buildah unmount ${container}

rm -rf .$PWD/sdk/binutils-2.35
rm -rf .$PWD/sdk/llvm-project-llvmorg-11.0.0-rc2

buildah rm ${container}