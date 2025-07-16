#!/usr/bin/env bash

set -eu

export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:+:}${PKG_CONFIG_PATH:-}"

unset build_alias
unset host_alias


ghc-pkg recache
ghc-pkg list --package-db="${BUILD_PREFIX}"/lib/ghc-9.12.2/lib/package.conf.d

# Install bootstrapping cabal (from conda-forge)
conda create -n cabal_env -y
conda install -n cabal_env -y --use-local ${RECIPE_DIR}/cabal-3.14.2.0-pl5321hf81b287_0.conda
# mamba create -n cabal_env -y --file ${RECIPE_DIR}/cabal-3.14.2.0-pl5321hf81b287_0.conda
CABAL_BS=$(mamba run -n cabal_env which cabal | grep -Eo '/.*cabal' | tail -n 1)
export CABAL_BS

${CABAL_BS} clean
rm -rf dist-newstyle
rm -rf ~/.cabal/store ~/.cabal/packages

${CABAL_BS} update

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

${CABAL_BS} install \
  --project-file=cabal.release.constraints.project \
  --installdir=${PREFIX}/bin \
  --install-method=copy \
  --enable-shared \
  --disable-static \
  --minimize-conflict-set \
  --constraint="Cabal ==3.14.1.0" \
  cabal-install -v3

# Install lib pkg
mkdir -p ${PREFIX}/lib/cabal-${PKG_VERSION}/package.conf.d
${CABAL_BS} install \
  --project-file=cabal.release.constraints.project \
  --package-db=${PREFIX}/lib/cabal-${PKG_VERSION}/package.conf.d
  --enable-shared \
  --disable-static \
  --minimize-conflict-set \
  --lib \
  Cabal-${PKG_VERSION}
