#!/bin/zsh
# Builds the WuyinLlama GDExtension and copies it to game/addons/wuyin_llama/bin.
#   tools/build_llama_extension.sh macos|android
# Env: LLAMA_DIR, GODOTCPP_DIR (default: ~/AppFactory/vendor-downloads/...), ANDROID_HOME (android)
set -e
cd "${0:A:h}/.."
TARGET=${1:-macos}
LLAMA_DIR=${LLAMA_DIR:-$HOME/AppFactory/vendor-downloads/llama.cpp-v0.7.0}
GODOTCPP_DIR=${GODOTCPP_DIR:-$HOME/AppFactory/vendor-downloads/godot-cpp}
OUT=game/addons/wuyin_llama/bin
mkdir -p $OUT
COMMON=(-S addons/llama -G Ninja -DCMAKE_BUILD_TYPE=Release -DLLAMA_DIR=$LLAMA_DIR -DGODOTCPP_DIR=$GODOTCPP_DIR)
case $TARGET in
  macos)
    cmake -B build/llama-macos $COMMON -DCMAKE_OSX_ARCHITECTURES=arm64
    cmake --build build/llama-macos --target wuyin_llama -j 10
    cp build/llama-macos/libwuyin_llama.macos.dylib $OUT/
    ;;
  android)
    NDK=$(ls -d $ANDROID_HOME/ndk/* | tail -1)
    # armv8.7-a: dotprod + i8mm (Snapdragon 8 Gen 1 and newer, target devices of the GDD).
    cmake -B build/llama-android $COMMON -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
      -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-28 \
      -DCMAKE_C_FLAGS="-march=armv8.7a" -DCMAKE_CXX_FLAGS="-march=armv8.7a"
    cmake --build build/llama-android --target wuyin_llama -j 10
    cp build/llama-android/libwuyin_llama.android.arm64.so $OUT/
    ;;
esac
ls -la $OUT
