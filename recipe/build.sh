#!/bin/bash
export LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$PREFIX/lib:$LIBRARY_PATH"
export C_INCLUDE_PATH="$PREFIX/include:$C_INCLUDE_PATH"
echo "Content PREFIX bin"
ls -lrt $PREFIX/bin
echo "Content PREFIX lib"
ls -lrt $PREFIX/lib
echo "Content PREFIX bin"
ls -lrt $BUILD_PREFIX/bin
echo "ALL ENVS"
env

if [ -f "$BUILD_PREFIX/bin/x86_64-conda_cos6-linux-gnu-gcc" ]; then
   echo "Setting x86_64-conda_cos6-linux-gnu-gcc"
   x86_64-conda_cos6-linux-gnu-gcc --version
   export CC="x86_64-conda_cos6-linux-gnu-gcc"
   ln -s $BUILD_PREFIX/bin/x86_64-conda_cos6-linux-gnu-ld $PREFIX/bin/ld
   ln -s $BUILD_PREFIX/bin/x86_64-conda_cos6-linux-gnu-gcc $PREFIX/bin/gcc
   rm $BUILD_PREFIX/bin/x86_64-conda_cos6-linux-gnu-cc
   #cp $BUILD_PREFIX/bin/x86_64-conda_cos6-linux-gnu-gcc $BUILD_PREFIX/bin/x86_64-conda_cos6-linux-gnu-cc
   gcc --version
   export EXTRA_CONFIGURE_OPTS=" --with-gcc=$BUILD_PREFIX/bin/x86_64-conda_cos6-linux-gnu-gcc --extra-include-dirs=$PREFIX/include --extra-lib-dirs=$PREFIX/lib $EXTRA_CONFIGURE_OPTS";
else
   echo "Setting LD path"
   export LD_LIBRARY_PATH="/lib64:$LD_LIBRARY_PATH"
   export LIBRARY_PATH="/lib64:$LIBRARY_PATH"
   export EXTRA_CONFIGURE_OPTS=" --extra-include-dirs=$PREFIX/include --extra-lib-dirs=$PREFIX/lib $EXTRA_CONFIGURE_OPTS";
fi
echo "which ld"
which ld
echo "which gcc"
which gcc
ghc-pkg recache
cd cabal-install
echo "Extra configure opts"
echo "$EXTRA_CONFIGURE_OPTS"
./bootstrap.sh
