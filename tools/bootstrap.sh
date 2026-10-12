#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/.." && pwd)
clingo_source=${CLINGO_SOURCE:-"$project_root/_source"}
if [[ -z ${CLINGO_SOURCE:-} && -d "$project_root/../clingo-5.8.2" ]]; then
  clingo_source="$project_root/../clingo-5.8.2"
fi
clingo_commit=a99ffb2a58293c68b28fcc283a1d1c9ccad900fe
build_dir=${CLINGO_BUILD_DIR:-"$project_root/_native"}
install_dir=${CLINGO_INSTALL_DIR:-"$project_root/_upstream"}
sanitizer_flags=${CLINGO_SANITIZERS:+"-fsanitize=$CLINGO_SANITIZERS -fno-omit-frame-pointer"}
if [[ ! -d "$clingo_source" ]]; then
  git clone --depth 1 --branch v5.8.2 https://github.com/potassco/clingo.git "$clingo_source"
fi
if [[ $(git -C "$clingo_source" rev-parse HEAD) != "$clingo_commit" ]]; then
  echo "Expected clingo v5.8.2 ($clingo_commit)" >&2
  exit 1
fi
git -C "$clingo_source" diff --exit-code HEAD --
cmp "$project_root/c_src/clingo.h" "$clingo_source/libclingo/clingo.h"
# Build a private, patched export; never modify the caller's upstream checkout.
patch="$project_root/tools/patches/clingo-5.8.2.patch"
mkdir -p "$build_dir"
build_dir=$(cd "$build_dir" && pwd)
if ! cmp -s "$patch" "$build_dir/.upstream.patch"; then
  rm -rf "$build_dir/source"
  mkdir "$build_dir/source"
  git -C "$clingo_source" archive "$clingo_commit" | tar -x -C "$build_dir/source"
  (cd "$build_dir/source" && git apply "$patch")
  cp "$patch" "$build_dir/.upstream.patch"
fi
cmake -S "$build_dir/source" -B "$build_dir/build" \
  -DCMAKE_BUILD_TYPE=Release -DCLINGO_BUILD_SHARED=ON \
  -DCLINGO_BUILD_APPS=OFF -DCLINGO_BUILD_TESTS=OFF \
  -DCMAKE_DISABLE_FIND_PACKAGE_RE2C=ON \
  -DCLINGO_BUILD_WITH_PYTHON="${CLINGO_PYTHON:-OFF}" \
  -DCLINGO_BUILD_WITH_LUA="${CLINGO_LUA:-OFF}" \
  -DCMAKE_C_FLAGS="${sanitizer_flags:-}" -DCMAKE_CXX_FLAGS="${sanitizer_flags:-}" \
  -DCMAKE_INSTALL_PREFIX="$install_dir"
cmake --build "$build_dir/build" --parallel "${BUILD_JOBS:-4}"
cmake --install "$build_dir/build"
mkdir -p "$install_dir/share/clingo_elixir"
cp "$patch" "$install_dir/share/clingo_elixir/upstream.patch"
