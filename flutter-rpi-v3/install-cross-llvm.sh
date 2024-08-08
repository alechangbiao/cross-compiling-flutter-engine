#  Home dir - /root
LLVM_SRC="/sdk/llvm-project-llvmorg-11.0.0-rc2/"
BINUTILS_SRC="/sdk/binutils-2.35/"
LLVM_SRC_BUILD="/root/llvm_build"
LLVM_LIBCXXABI_BUILD="/root/llvm_libcxxabi_build"
LLVM_LIBCXX_BUILD="/root/llvm_libcxx_build"

INSTALL_PATH="/usr/local/cross_armhf_clang_11.0.0-rc2"

rm -rf $LLVM_SRC_BUILD \
&& rm -rf $LLVM_LIBCXX_BUILD \
&& rm -rf $LLVM_LIBCXXABI_BUILD \
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
  && ninja install
