#!/usr/bin/env bash

set -eux

# Environment setup
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:+:}${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="${PREFIX}/lib:${BUILD_PREFIX}/lib${LD_LIBRARY_PATH:+:}${LD_LIBRARY_PATH:-}"
export LIBRARY_PATH="${PREFIX}/lib:${BUILD_PREFIX}/lib${LIBRARY_PATH:+:}${LIBRARY_PATH:-}"
export PATH="${BUILD_PREFIX}/ghc-bootstrap/bin${PATH:+:}${PATH:-}"

unset build_alias
unset host_alias

# Determine fallback URL based on platform
get_fallback_url() {
  local version="${1}"
  case "${build_platform}" in
    linux-64)
      echo "https://downloads.haskell.org/~cabal/cabal-install-${version}/cabal-install-${version}-x86_64-linux-ubuntu20_04.tar.xz"
      ;;
    osx-64)
      echo "https://downloads.haskell.org/~cabal/cabal-install-${version}/cabal-install-${version}-x86_64-apple-darwin.tar.xz"
      ;;
    *)
      echo "https://downloads.haskell.org/~cabal/cabal-install-${version}/cabal-install-${version}-x86_64-unknown-mingw32.tar.xz"
      ;;
  esac
}

# Clean cabal environment
clean_cabal() {
  "${CABAL}" clean
  rm -rf dist-newstyle
  rm -rf ~/.cabal/store ~/.cabal/packages
  "${CABAL}" update
}

# Install cabal with given parameters
install_cabal() {
  local install_dir="${1}"
  "${CABAL}" install \
    --project-file=cabal.release.constraints.project \
    --installdir="${install_dir}" \
    --install-method=copy \
    --minimize-conflict-set \
    cabal-install
}

# Main build process
main() {
  # Initialize package database
  ghc-pkg recache

  # Install bootstrapping cabal from conda-forge
  conda create -n cabal_env -y -c conda-forge cabal
  CABAL="conda run -n cabal_env cabal"
  export CABAL

  echo "Bootstrap cabal version: $(${CABAL} --version)"

  # Create project configuration
  cat > cabal.release.constraints.project << EOF
allow-newer:
    *:base,
    *:ghc-prim,
    *:template-haskell,
    *:Cabal,
    *:Cabal-syntax,
    tasty:tagged
EOF

  # Append release project if it exists
  if [[ -f cabal.release.project ]]; then
      cat cabal.release.project >> cabal.release.constraints.project
  fi

  # Try building with bootstrap cabal
  if ! install_cabal "${PREFIX}/bin"; then
    echo "Bootstrap build failed, downloading fallback cabal-install-${PKG_VERSION}"

    # Download fallback version
    FALLBACK_URL=$(get_fallback_url "${PKG_VERSION}")
    mkdir -p fallback-cabal
    pushd fallback-cabal

    if curl -L -o "cabal-install-${PKG_VERSION}.tar.xz" "${FALLBACK_URL}"; then
      echo "Downloaded fallback cabal-install-${PKG_VERSION}"
      tar xf "cabal-install-${PKG_VERSION}.tar.xz" && chmod +x cabal
      echo "Fallback installation successful"
    else
      echo "Fallback download failed"
      exit 1
    fi
    popd

    # Use fallback cabal to build final version
    export CABAL="${SRC_DIR}/fallback-cabal/cabal"
    clean_cabal

    echo "Building from source"
    install_cabal "${PREFIX}/bin"
  fi

  # Verify installation
  echo "Verifying installation:"
  "${PREFIX}/bin/cabal" --version
}

# Run main function
main
