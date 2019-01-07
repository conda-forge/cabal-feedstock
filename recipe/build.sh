#!/bin/bash
export LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$PREFIX/lib:$LIBRARY_PATH"
export C_INCLUDE_PATH="$PREFIX/include:$C_INCLUDE_PATH"
echo "ENVIRONMENT"
echo "CC"
echo "$CC"
echo "LD"
echo "$LD"
echo "Content PREFIX bin"
ls -lrt $PREFIX/bin
echo "Content PREFIX lib"
ls -lrt $PREFIX/lib
if [ -f "$BUILD_PREFIX/bin/x86_64-conda_cos6-linux-gnu-gcc" ]; then
   export CC="x86_64-conda_cos6-linux-gnu-gcc"
   echo "Setting x86_64-conda_cos6-linux-gnu-gcc"
fi
ghc-pkg recache
cd cabal-install
export EXTRA_CONFIGURE_OPTS="-threaded --extra-include-dirs=$PREFIX/include --extra-lib-dirs=$PREFIX/lib $EXTRA_CONFIGURE_OPTS";
echo "Extra configure opts"
echo "$EXTRA_CONFIGURE_OPTS"
./bootstrap.sh
