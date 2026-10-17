#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
case "$(uname -s)-$(uname -m)" in
  Linux-x86_64) host=linux-x86_64 ;;
  Linux-aarch64) host=linux-aarch64 ;;
  Darwin-x86_64) host=macos-x86_64 ;;
  Darwin-arm64) host=macos-aarch64 ;;
  MINGW*-x86_64) host=windows-x86_64 ;;
  *) echo 'Unsupported build host' >&2; exit 1 ;;
esac
target=${CLINGO_TARGET:-$host}
cache=${CLINGO_BUILD_ROOT:-${XDG_CACHE_HOME:-$HOME/.cache}/clingo-elixir/$target}
mkdir -p "$cache" native/licenses
cache=$(cd "$cache" && pwd -P)
source=${CLINGO_SOURCE:-${XDG_CACHE_HOME:-$HOME/.cache}/clingo-elixir/source}
[ -d "$source" ] || git clone --depth 1 --branch v5.8.2 https://github.com/potassco/clingo.git "$source"
source=$(cd "$source" && pwd -P)
commit=a99ffb2a58293c68b28fcc283a1d1c9ccad900fe
[ "$(git -C "$source" rev-parse HEAD)" = "$commit" ]
git -C "$source" diff --exit-code HEAD --
cmp c_src/clingo.h "$source/libclingo/clingo.h"
patch="$PWD/tools/patches/clingo-5.8.2.patch"
if ! cmp -s "$patch" "$cache/.upstream.patch"; then
  elixir --erl '+S 1:1' -e 'File.rm_rf!(hd(System.argv()))' "$cache/source"
  mkdir -p "$cache/source"
  git -C "$source" archive "$commit" | tar -x -C "$cache/source"
  (cd "$cache/source" && git apply "$patch")
  cp "$patch" "$cache/.upstream.patch"
fi
cc=${CC:-cc}
cxx=${CXX:-c++}
strip_command=strip
extension=so
flags=()
link_flags=()
cmake_flags=()
case "$target" in
  linux-x86_64|linux-aarch64)
    link_flags+=(-static-libstdc++ -static-libgcc)
    if [ "$target" != "$host" ]; then
      [ "$target" = linux-aarch64 ] || { echo 'Use a matching Linux build host' >&2; exit 1; }
      cc=aarch64-linux-gnu-gcc
      cxx=aarch64-linux-gnu-g++
      strip_command=aarch64-linux-gnu-strip
      cmake_flags+=(-DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=aarch64)
    fi
    ;;
  windows-x86_64)
    extension=dll
    flags+=(-D_WIN32_WINNT=0x0601)
    link_flags+=(-static -static-libgcc -static-libstdc++)
    if [ "$host" != "$target" ]; then
      cc=x86_64-w64-mingw32-gcc-posix
      cxx=x86_64-w64-mingw32-g++-posix
      strip_command=x86_64-w64-mingw32-strip
      cmake_flags+=(-DCMAKE_SYSTEM_NAME=Windows -DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres)
    fi
    ;;
  macos-x86_64|macos-aarch64)
    [ "$target" = "$host" ] || { echo 'Build macOS bundles on matching macOS machines' >&2; exit 1; }
    export MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET:-12.0}
    cmake_flags+=("-DCMAKE_OSX_DEPLOYMENT_TARGET=$MACOSX_DEPLOYMENT_TARGET")
    ;;
  *) echo "Unsupported target: $target" >&2; exit 1 ;;
esac
if [ -n "${CLINGO_BUILD_SYSROOT:-}" ]; then
  flags+=("--sysroot=$CLINGO_BUILD_SYSROOT")
  cmake_flags+=("-DCMAKE_SYSROOT=$CLINGO_BUILD_SYSROOT")
fi
read -r -a user_flags <<< "${CFLAGS:-}"
flags+=("${user_flags[@]}")
cmake -S "$cache/source" -B "$cache/build" -G Ninja \
  "${cmake_flags[@]}" -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER="$cc" -DCMAKE_CXX_COMPILER="$cxx" \
  -DCMAKE_C_FLAGS="${flags[*]}" -DCMAKE_CXX_FLAGS="${flags[*]}" \
  -DCMAKE_SHARED_LINKER_FLAGS="${link_flags[*]}" \
  -DCMAKE_INSTALL_PREFIX="$cache/install" -DCMAKE_INSTALL_LIBDIR=lib \
  -DCLINGO_BUILD_SHARED=ON -DCLINGO_BUILD_APPS=OFF -DCLINGO_BUILD_TESTS=OFF \
  -DCLINGO_BUILD_WITH_PYTHON=OFF -DCLINGO_BUILD_WITH_LUA=OFF \
  -DCMAKE_DISABLE_FIND_PACKAGE_RE2C=ON -DCLINGO_MANAGE_RPATH=OFF
cmake --build "$cache/build" --parallel "${BUILD_JOBS:-4}"
cmake --install "$cache/build"
mkdir -p "$cache/install/share/clingo_elixir"
cp "$patch" "$cache/install/share/clingo_elixir/upstream.patch"
# Build against pinned OTP 29 headers regardless of the host OTP version.
mkdir -p "$cache/otp"
for file in erl_nif.h erl_drv_nif.h erl_nif_api_funcs.h; do
  [ -f "$cache/otp/$file" ] || curl -fLsS "https://raw.githubusercontent.com/erlang/otp/OTP-29.0/erts/emulator/beam/$file" -o "$cache/otp/$file"
  case "$file" in
    erl_nif.h) checksum=6cb96c37d306a173ef71946e823829fc21e47cb4a19288b221129eac2f13b689 ;;
    erl_drv_nif.h) checksum=e9d4280779e8fd4ac463144f310b4da2346dd3a18e73d445bf1f88ae3c1f1312 ;;
    erl_nif_api_funcs.h) checksum=cf34ada521aeb0ee00c9936320cd694f9816edbab960500453051cea443dda11 ;;
  esac
  elixir --erl '+S 1:1' -e '[file, expected] = System.argv(); actual = :crypto.hash(:sha256, File.read!(file)) |> Base.encode16(case: :lower); if actual != expected, do: raise("OTP header checksum mismatch")' "$cache/otp/$file" "$checksum"
done
sed -n '/%CopyrightBegin%/,/%CopyrightEnd%/p' "$cache/otp/"*.h > native/licenses/Erlang-NOTICES.txt
include=$(erl +S 1:1 -noshell -eval 'io:format("~s/usr/include", [code:root_dir()]), halt().')
cp "$include/erl_int_sizes_config.h" "$cache/otp/"
if [ "$extension" = dll ]; then
  sed -i.bak 's/#define SIZEOF_LONG 8/#define SIZEOF_LONG 4/' "$cache/otp/erl_int_sizes_config.h"
fi
elixir --erl '+S 1:1' -e 'File.rm_rf!(hd(System.argv()))' "$cache/stage"
make -B CC="$cc" ERL_INCLUDE="$cache/otp" CLINGO_PREFIX="$cache/install" \
  DESTDIR="$cache/stage/clingo" NIF_EXT="$extension" \
  CFLAGS="-O2 -Wall -Wextra -std=c11 ${flags[*]}"
home="$cache/stage/clingo"
echo "$target" > "$home/target"
cp c_src/clingo.h "$home/"
cp "$patch" "$home/upstream.patch"
cp "$source/LICENSE.md" native/licenses/clingo-LICENSE.md
cp "$source/clasp/LICENSE" native/licenses/clasp-LICENSE.txt
cp "$source/clasp/libpotassco/LICENSE" native/licenses/potassco-LICENSE.txt
for component in hopscotch-map ordered-map sparse-map; do
  cp "$source/third_party/$component/LICENSE" "native/licenses/$component-LICENSE.txt"
done
cp "$source/third_party/optional/COPYING" native/licenses/optional-LICENSE.txt
cp "$source/third_party/variant/LICENSE.md" native/licenses/variant-LICENSE.md
cp "$source/third_party/wide-integer/LICENSE_1_0.txt" native/licenses/wide-integer-LICENSE.txt
cp -a native/licenses "$home/licenses"
if [[ "$target" == linux-* ]]; then
  for binary in "$home/clingo" "$home/clingo_elixir.so" "$home/libclingo.so.4"; do
    patchelf --set-rpath '$ORIGIN' "$binary"
    "$strip_command" "$binary"
    required=$(readelf --version-info "$binary" | sed -n 's/.*Name: GLIBC_\([0-9.]*\).*/\1/p' | sort -V | tail -n 1)
    if [ "$(printf '%s\n' "$required" 2.38 | sort -V | tail -n 1)" != 2.38 ]; then
      echo "$binary requires glibc $required; use a compatible toolchain/sysroot." >&2
      exit 1
    fi
  done
elif [ "$extension" = dll ]; then
  for binary in "$home"/*.dll "$home"/*.exe; do "$strip_command" "$binary"; done
else
  library="$home/libclingo.4.dylib"
  install_name_tool -id '@rpath/libclingo.4.dylib' "$library"
  for binary in "$home/clingo" "$home/clingo_elixir.so"; do
    dependency=$(otool -L "$binary" | awk '/libclingo.*dylib/ {print $1}')
    install_name_tool -change "$dependency" '@rpath/libclingo.4.dylib' "$binary"
  done
  for binary in "$home/clingo" "$home/clingo_elixir.so" "$library"; do
    strip -x "$binary"
    codesign --force --sign - "$binary"
  done
fi
archive="native/clingo-5.8.2-$target.tar.gz"
tar -czf "$archive" -C "$cache/stage" clingo
elixir --erl '+S 1:1' -e '[file] = System.argv(); hash = :crypto.hash(:sha256, File.read!(file)) |> Base.encode16(case: :lower); File.write!(file <> ".sha256", hash <> "\n")' "$archive"
