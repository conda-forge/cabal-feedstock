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
  local platform="${build_platform:-$(uname -s | tr '[:upper:]' '[:lower:]')}"
  
  case "${platform}" in
    linux-64|linux)
      echo "https://downloads.haskell.org/~cabal/cabal-install-${version}/cabal-install-${version}-x86_64-linux-ubuntu20_04.tar.xz"
      ;;
    osx-64|darwin)
      echo "https://downloads.haskell.org/~cabal/cabal-install-${version}/cabal-install-${version}-x86_64-darwin.tar.xz"
      ;;
    win-64|mingw*|msys*|cygwin*)
      echo "https://downloads.haskell.org/~cabal/cabal-install-${version}/cabal-install-${version}-x86_64-windows.tar.xz"
      ;;
  esac
}

# Download and extract fallback cabal
download_fallback_cabal() {
  local version="${1}"
  local url=$(get_fallback_url "${version}")
  local filename=$(basename "${url}")
  
  echo "Downloading fallback cabal-install-${version}"
  mkdir -p fallback-cabal
  pushd fallback-cabal
  
  if curl -L -o "${filename}" "${url}"; then
    echo "Downloaded fallback cabal-install-${version}"
    
    # Extract based on file extension
    case "${filename}" in
      *.zip)
        unzip -q "${filename}" && chmod +x cabal
        ;;
      *.tar.xz)
        xz -d "${filename}" && tar xf "${filename%.xz}"
        chmod +x cabal
        ;;
      *)
        echo "Unknown file format: ${filename}"
        popd
        return 1
        ;;
    esac
    
    echo "Fallback installation successful"
    popd
    export CABAL="${SRC_DIR}/fallback-cabal/cabal"
    return 0
  else
    echo "Fallback download failed"
    popd
    return 1
  fi
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
  if ! conda create -n cabal_env -y -c conda-forge cabal; then
    echo "Conda cabal install failed, downloading fallback cabal-install-${PKG_VERSION}"
    if ! download_fallback_cabal "${PKG_VERSION}"; then
      exit 1
    fi
  else
    export CABAL="conda run -n cabal_env cabal"
  fi

  echo "Bootstrap cabal version: $(${CABAL} --version)"
  clean_cabal || true

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
    
    if ! download_fallback_cabal "${PKG_VERSION}"; then
      exit 1
    fi
    
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
