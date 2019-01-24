#!/bin/bash
export LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$PREFIX/lib:$LIBRARY_PATH"
export C_INCLUDE_PATH="$PREFIX/include:$C_INCLUDE_PATH"
export LD="x86_64-conda_cos6-linux-gnu-ld"
ghc-pkg recache
ghc-pkg describe rts
ghc-pkg describe rts > rts.pkg
perl -pi -e 's/$PREFIX\/lib\/ghc-8.2.2\/rts/$PREFIX\/lib\/ghc-8.2.2\/rts \$\{pkgroot\}\/../g' rts.pkg
cat rts.pkg
ghc-pkg update rts.pkg
echo "Setting x86_64-conda_cos6-linux-gnu-gcc"
echo "GCC version"
x86_64-conda_cos6-linux-gnu-gcc --version
echo "CC version"
x86_64-conda_cos6-linux-gnu-cc --version
echo "Collect2"
x86_64-conda_cos6-linux-gnu-cc -print-prog-name=collect2
echo "ld"
x86_64-conda_cos6-linux-gnu-cc -print-prog-name=ld
echo "LD version"
x86_64-conda_cos6-linux-gnu-ld --version
echo "LD help"
x86_64-conda_cos6-linux-gnu-ld --help
export EXTRA_CONFIGURE_OPTS=" --extra-include-dirs=$PREFIX/include --extra-lib-dirs=$PREFIX/lib ";
sed -i -- 's/collect2 //g' cabal-install/bootstrap.sh
ghc-pkg recache
cd cabal-install
echo "Extra configure opts"
echo "$EXTRA_CONFIGURE_OPTS"
sed -i -- 's/export LD=$LINK/export LINK=x86_64-conda_cos6-linux-gnu-cc/g' bootstrap.sh
#sed -i -- 's/args="$args ${EXTRA_CONFIGURE_OPTS} ${VERBOSE}"/args="$args ${EXTRA_CONFIGURE_OPTS} ${VERBOSE}"\n echo -e "$args"\n/g' bootstrap.sh
sed -i -- 's/${GHC} --make ${JOBS} ${PKG_DBS} Setup -o Setup/${GHC} -lgmp -threaded -pgmc x86_64-conda_cos6-linux-gnu-cc -pgml x86_64-conda_cos6-linux-gnu-cc --make ${JOBS} ${PKG_DBS} Setup -o Setup/g' bootstrap.sh
cat bootstrap.sh
./bootstrap.sh --no-doc
