#!/usr/bin/env bash

set -eu -o pipefail

# Environment setup
export PKG_CONFIG_PATH="${BUILD_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:+:}${PKG_CONFIG_PATH:-}"
export LIBRARY_PATH="${BUILD_PREFIX}/lib:${PREFIX}/lib${LIBRARY_PATH:+:}${LIBRARY_PATH:-}"
export PATH="${BUILD_PREFIX}/ghc-bootstrap/bin${PATH:+:}${PATH:-}"

unset build_alias
unset host_alias

# Clean cabal environment
clean_cabal() {
  eval ${CABAL} clean
  rm -rf dist-newstyle
  rm -rf ~/.cabal/store ~/.cabal/packages
  # Also clean the new v3.10.3.0 store location
  rm -rf ~/.local/state/cabal/store
  eval ${CABAL} update
}

# Install cabal with given parameters
install_cabal() {
  local install_dir="${1}"

  ${CABAL} install \
    --project-file=cabal.release.constraints.project \
    --installdir="${install_dir}" \
    --install-method=copy \
    --minimize-conflict-set \
    ${CABAL_CONFIG_FLAGS:-} \
    cabal-install
}

# Main build process
main() {
  export CABAL=$(find "${SRC_DIR}"/cabal-bootstrap -name "cabal*" -type f | head -1)
  chmod +x "${CABAL}"

  if [[ "${target_platform}" == "win-"* ]]; then
    export CC=${GCC}
    export CABAL_CONFIG_FLAGS="--enable-static --disable-shared --ghc-options=-static"
    
  elif [[ "${target_platform}" == "osx-"* ]]; then
    export CABAL_CONFIG_FLAGS="-v2 --ghc-options=-optl-Wl,-dead_strip --disable-library-profiling --enable-static --disable-shared"
    export CFLAGS="$CFLAGS -target x86_64-apple-darwin13.4.0"
    export LDFLAGS="$LDFLAGS -target x86_64-apple-darwin13.4.0"
    export CC_FOR_BUILD="$CC -target x86_64-apple-darwin13.4.0"
    export MACOSX_DEPLOYMENT_TARGET="10.13"
    export AR="$AR"
    export RANLIB="$RANLIB"
    
    settings_file="${BUILD_PREFIX}"/ghc-bootstrap/lib/ghc-9.6.7/lib/settings
    # Fix GHC settings to use conda-provided libiconv
    # sed -i -E "s#[^ ]*libiconv.2.tbd -L[^ ]*private#-v -liconv#g" "${settings_file}"
    # sed -i -E "s#(ld flags\", \")#\1-v -L\$topdir/../../../../lib -liconv #" "${settings_file}"
    
    # SDK
    sed -i "s#[^ ]*libiconv.2.tbd -L[^ ]*private#${SDKROOT}/usr/lib/libiconv.2.tbd#g" "${settings_file}"
    sed -i -E "s#(ld flags\", \")#\1 ${SDKROOT}/usr/lib/libiconv.2.tbd#" "${settings_file}"

    # Force architecture and deployment target in GHC settings
    sed -i -E "s#(C compiler flags\", \")#\1-target x86_64-apple-darwin13.4.0 #" "${settings_file}"
    sed -i -E "s#(C compiler link flags\", \")#\1-target x86_64-apple-darwin13.4.0 -Wl,${SDKROOT}/usr/lib/libiconv.2.tbd #" "${settings_file}"

    sed -i -E "s#(C\+\+ compiler flags\", \")#\1-target x86_64-apple-darwin13.4.0 #" "${settings_file}"
    sed -i -E "s#(C\+\+ compiler link flags\", \")#\1-target x86_64-apple-darwin13.4.0 -Wl,${SDKROOT}/usr/lib/libiconv.2.tbd #" "${settings_file}"


  elif [[ "${target_platform}" == "linux-64" ]]; then
    # Correct the libc.so script to avoid trying to load /lib64/libc.so.6
    sysroot_libc_script="${BUILD_PREFIX}/x86_64-conda-linux-gnu/sysroot/usr/lib64/libc.so"
    sed -i "s|/lib64/libc.so.6|libc.so.6|g" "$sysroot_libc_script"
    sed -i "s|/usr/lib64/libc_nonshared.a|libc_nonshared.a|g" "$sysroot_libc_script"
    sed -i "s|/lib64/ld-linux-x86-64.so.2|ld-2.17.so|g" "$sysroot_libc_script"

    # Ensure sysroot used for cabal
    patchelf --remove-rpath "${CABAL}"
    patchelf --force-rpath --set-rpath "${BUILD_PREFIX}/x86_64-conda-linux-gnu/sysroot/lib64:${BUILD_PREFIX}/x86_64-conda-linux-gnu/sysroot/usr/lib64:${BUILD_PREFIX}/ghc-bootstrap/lib/ghc-9.6.7/lib/x86_64-linux-ghc-9.6.7:${BUILD_PREFIX}/x86_64-conda-linux-gnu/lib:${BUILD_PREFIX}/lib" "${CABAL}"
 
    # Set interpreter for compilation by bootstrap
    patchelf --set-interpreter "${BUILD_PREFIX}/x86_64-conda-linux-gnu/sysroot/lib64/ld-2.17.so" "${CABAL}"
    
    export CABAL_CONFIG_FLAGS=""
    export C_INCLUDE_PATH="${BUILD_PREFIX}/include:${C_INCLUDE_PATH:-}"
    
  else
    echo "Conda system ${target_platform} not supported"
    exit 1
  fi

  clean_cabal

  # Append release project if it exists
  if [[ -f cabal.release.project ]]; then
    cat cabal.release.project > cabal.release.constraints.project
  elif [[ -f cabal.project.release ]]; then
    cat cabal.project.release > cabal.release.constraints.project
  elif [[ -f cabal.project ]]; then
    cat cabal.project > cabal.release.constraints.project
  else
    echo "No cabal project file found"
    exit 1
  fi

  # Remove static linking zlib (no longer an issue post 3.14)
  sed -i 's|package zlib$||' cabal.release.constraints.project
  sed -i 's|  flags: -pkg-config +bundled-c-zlib||' cabal.release.constraints.project
  
  # Create project configuration
  cat >> cabal.release.constraints.project << EOF
allow-newer:
    *:base
constraints:
    lukko -ofd-locking
EOF

  # Add architecture flags for macOS to ensure consistent compilation
  if [[ "${target_platform}" == "osx-"* ]]; then
    cat >> cabal.release.constraints.project << EOF

library-profiling: False
shared: False
static: True
executable-static: True
split-sections: False
split-objs: False

package *
  ghc-options: -optc-target=x86_64-apple-darwin13.4.0 -optl-target=x86_64-apple-darwin13.4.0
  shared: False
  static: True
EOF
  fi

  # Try building with bootstrap cabal
  if ! install_cabal "${PREFIX}/bin"; then
    echo "Binary dist cabal-install-${PKG_VERSION} failed to build"
    mv /home/conda/.cache/cabal/logs ${SRC_DIR}/_logs 2>/dev/null || true
    exit 1
  fi

  if [[ "${target_platform}" == "linux-64" ]]; then
    # Reset interpreter to default (it should work with any libc >= 2.17)
    patchelf --remove-rpath "${CABAL}"
    patchelf --force-rpath --set-rpath "${PREFIX}/x86_64-conda-linux-gnu/sysroot/lib64:${PREFIX}/x86_64-conda-linux-gnu/sysroot/usr/lib64:${PREFIX}/ghc-bootstrap/lib/ghc-9.6.7/lib/x86_64-linux-ghc-9.6.7:${PREFIX}/x86_64-conda-linux-gnu/lib:${PREFIX}/lib" "${CABAL}"
    patchelf --set-interpreter "/lib64/ld-linux-x86-64.so.2" "${PREFIX}"/bin/cabal
  fi
}

# Run main function
main
