#!/usr/bin/env bash

set -eu

export PATH="${SRC_DIR}"/bootstrap-cabal:"${BUILD_PREFIX}"/ghc-bootstrap/bin:"${PREFIX}"/ghc-bootstrap/bin"${PATH:+:}${PATH:-}"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:+:}${PKG_CONFIG_PATH:-}"

unset build_alias
unset host_alias


ghc-pkg recache

cabal clean
rm -rf dist-newstyle
rm -rf ~/.cabal/store ~/.cabal/packages

cabal update

# This is likely version specific
cat > cabal.release.constraints.project << EOF
  constraints:
    base installed,
    ghc-bignum installed,
    ghc-prim installed

  allow-newer:
    *:base,
    *:ghc-prim,
    *:template-haskell,
    tasty:tagged
EOF
cat cabal.release.project >> cabal.release.constraints.project

cabal install \
  --project-file=cabal.release.constraints.project \
  --installdir=${PREFIX}/bin \
  --install-method=copy \
  --enable-shared \
  --disable-static \
  --allow-boot-library-installs \
  --minimize-conflict-set \
  cabal-install
