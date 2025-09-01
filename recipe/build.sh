#!/usr/bin/env bash

set -eu -o pipefail

# Environment setup
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:+:}${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="${PREFIX}/lib:${BUILD_PREFIX}/lib${LD_LIBRARY_PATH:+:}${LD_LIBRARY_PATH:-}"
export LIBRARY_PATH="${PREFIX}/lib:${BUILD_PREFIX}/lib${LIBRARY_PATH:+:}${LIBRARY_PATH:-}"
export PATH="${BUILD_PREFIX}/ghc-bootstrap/bin${PATH:+:}${PATH:-}"

unset build_alias
unset host_alias

# Clean cabal environment
clean_cabal() {
  eval ${CABAL} clean
  rm -rf dist-newstyle
  rm -rf ~/.cabal/store ~/.cabal/packages
  eval ${CABAL} update
}

# Install cabal with given parameters
install_cabal() {
  local install_dir="${1}"
  eval ${CABAL} install \
    --project-file=cabal.release.constraints.project \
    --installdir="${install_dir}" \
    --install-method=copy \
    --minimize-conflict-set \
    ${CABAL_CONFIG_FLAGS:-} \
    cabal-install
}

# Main build process
main() {
  # Initialize package database
  ghc-pkg recache
  
  # Configure GHC for Windows compatibility
  if [[ "${target_platform}" == win-* ]]; then
    export CC=${GCC}
    export CABAL_CONFIG_FLAGS="--enable-static --disable-shared --ghc-options=-static"
  elif [[ "${target_platform}" == osx-* ]]; then
    export CABAL_CONFIG_FLAGS="-v1 --enable-static --disable-shared --ghc-options=-optl-Wl,-dead_strip"
  else
    export C_INCLUDE_PATH="${PREFIX}/include:${C_INCLUDE_PATH:-}"
    export CABAL_CONFIG_FLAGS=""
  fi

  export CABAL=$(find "${SRC_DIR}"/cabal-bootstrap -name "cabal*" -type f | head -1)
  chmod +x "${CABAL}"
  clean_cabal || true

  # Append release project if it exists
  if [[ -f cabal.project.release ]]; then
      cat cabal.project.release > cabal.release.constraints.project
  fi

  # Create project configuration
  cat >> cabal.release.constraints.project << EOF
EOF
#allow-newer:
#    *:base,
#    *:template-haskell,
#    *:ghc-prim,
#    tasty:tagged
#EOF

  # Try building with bootstrap cabal
  if ! install_cabal "${PREFIX}/bin"; then
    echo "Binary dist cabal-install-${PKG_VERSION} failed to build itself"
    exit 1
  fi

  # Verify installation
  echo "Verifying installation:"
  "${PREFIX}/bin/cabal" --version
}

# Run main function
main
