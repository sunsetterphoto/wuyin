# WuyinLlama GDExtension: llama.cpp + godot-cpp, built for macOS (dev) and Android arm64.
#
#   tools/build_llama_extension.sh [macos|android]
#
# Sources of the two dependencies are passed in (not vendored in this repo):
#   -DLLAMA_DIR=<llama.cpp checkout> -DGODOTCPP_DIR=<godot-cpp checkout>
cmake_minimum_required(VERSION 3.22)
project(wuyin_llama C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(LLAMA_DIR "" CACHE PATH "llama.cpp source directory")
set(GODOTCPP_DIR "" CACHE PATH "godot-cpp source directory")

# godot-cpp against the API of the Godot version we ship (dumped from the engine).
set(GODOTCPP_CUSTOM_API_FILE "${CMAKE_CURRENT_SOURCE_DIR}/api/extension_api.json" CACHE FILEPATH "" FORCE)
set(GODOTCPP_TARGET "template_release" CACHE STRING "" FORCE)
add_subdirectory(${GODOTCPP_DIR} godot-cpp)

# llama.cpp: static, CPU only, with the common library (Jinja chat templates).
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_COMMON ON CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TOOLS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "" FORCE)
set(LLAMA_CURL OFF CACHE BOOL "" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
set(GGML_METAL OFF CACHE BOOL "" FORCE)
set(GGML_VULKAN OFF CACHE BOOL "" FORCE)
add_subdirectory(${LLAMA_DIR} llama)

add_library(wuyin_llama SHARED src/register_types.cpp src/wuyin_llama.cpp)
target_include_directories(wuyin_llama PRIVATE ${LLAMA_DIR}/include ${LLAMA_DIR}/common)
target_link_libraries(wuyin_llama PRIVATE godot::cpp llama llama-common)
if(ANDROID)
	set_target_properties(wuyin_llama PROPERTIES OUTPUT_NAME "wuyin_llama.android.arm64")
	target_link_options(wuyin_llama PRIVATE "-Wl,--gc-sections" "-s")
elseif(APPLE)
	set_target_properties(wuyin_llama PROPERTIES OUTPUT_NAME "wuyin_llama.macos" SUFFIX ".dylib")
endif()
