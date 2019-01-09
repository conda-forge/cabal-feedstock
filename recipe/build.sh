#!/bin/bash
export LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$PREFIX/lib:$LIBRARY_PATH"
export C_INCLUDE_PATH="$PREFIX/include:$C_INCLUDE_PATH"
echo "ENVIRONMENT"
echo "CC"
echo "$CC"
echo "LD"
echo "$LD"
echo "PATH"
echo "$PATH"
export PATH="$PREFIX/bin:$PATH"
echo "Content PREFIX bin"
ls -lrt $PREFIX/bin
echo "Content PREFIX lib"
ls -lrt $PREFIX/lib
echo "Content PREFIX bin"
ls -lrt $BUILD_PREFIX/bin
echo "ALL ENVS"
env

if [ -f "$BUILD_PREFIX/bin/x86_64-conda_cos6-linux-gnu-gcc" ]; then
   x86_64-conda_cos6-linux-gnu-gcc --version
   export CC="gcc"
   echo "Setting x86_64-conda_cos6-linux-gnu-cc"
   ln -s $BUILD_PREFIX/bin/x86_64-conda_cos6-linux-gnu-ld $PREFIX/bin/ld
   ln -s $BUILD_PREFIX/bin/x86_64-conda_cos6-linux-gnu-gcc $PREFIX/bin/gcc
   gcc --version
else
   echo "Setting LD path"
   export LD_LIBRARY_PATH="/lib64:$LD_LIBRARY_PATH"
   export LIBRARY_PATH="/lib64:$LIBRARY_PATH"
fi
echo "which ld"
which ld
echo "which gcc"
which gcc
ghc-pkg recache
cd cabal-install
export EXTRA_CONFIGURE_OPTS=" --ghc-options="-threaded" --extra-include-dirs=$PREFIX/include --extra-lib-dirs=$PREFIX/lib $EXTRA_CONFIGURE_OPTS";
echo "Extra configure opts"
echo "$EXTRA_CONFIGURE_OPTS"
./bootstrap.sh
