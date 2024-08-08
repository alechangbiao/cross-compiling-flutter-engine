./flutter/tools/gn                      \
    --target-sysroot /src/sysroot       \
    --target-toolchain /src/cross_armhf_clang_11.0.0-rc2 \
    --target-triple arm-linux-gnueabihf \
    --linux-cpu arm                     \
    --runtime-mode debug                \
    --embedder-for-target               \
    --no-lto                            \
    --target-os linux                   \
    --arm-float-abi hard