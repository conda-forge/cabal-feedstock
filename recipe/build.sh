#!/bin/bash
export LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$PREFIX/lib:$LIBRARY_PATH"
export C_INCLUDE_PATH="$PREFIX/include:$C_INCLUDE_PATH"
export LDFLAGS=" -lgmp $LDFLAGS"
echo $LDFLAGS
export LD="x86_64-conda_cos6-linux-gnu-ld"
#export CFFLAGS=""
echo "Content PREFIX bin"
ls -lrt $PREFIX/bin
echo "Content PREFIX lib"
ls -lrt $PREFIX/lib
echo "Content PREFIX bin"
ls -lrt $BUILD_PREFIX/bin
#echo "ALL ENVS" 
#env
#printf "#include <iostream>\nusing namespace std;\nint main()\n{\n    cout << \"Hello, World\";\n    return 0;\n}\n" > test.c
echo "Setting x86_64-conda_cos6-linux-gnu-gcc"
echo "GCC version"
x86_64-conda_cos6-linux-gnu-gcc --version
echo "CC version"
x86_64-conda_cos6-linux-gnu-cc --version
echo "Collect2"
x86_64-conda_cos6-linux-gnu-cc -print-prog-name=collect2
echo "Collect2"
x86_64-conda_cos6-linux-gnu-cc -print-prog-name=ld
echo "LD version"
x86_64-conda_cos6-linux-gnu-ld --version
echo "LD help"
x86_64-conda_cos6-linux-gnu-ld --help
#export CC="$BUILD_PREFIX/bin/x86_64-conda_cos6-linux-gnu-cc"
#export LD="$BUILD_PREFIX/bin/x86_64-conda_cos6-linux-gnu-ld"
ln -s $BUILD_PREFIX/bin/x86_64-conda_cos6-linux-gnu-ld $PREFIX/bin/ld
#ln -s $BUILD_PREFIX/bin/x86_64-conda_cos6-linux-gnu-gcc $PREFIX/bin/gcc
#rm $BUILD_PREFIX/bin/x86_64-conda_cos6-linux-gnu-cc
#cp $BUILD_PREFIX/bin/x86_64-conda_cos6-linux-gnu-gcc $BUILD_PREFIX/bin/x86_64-conda_cos6-linux-gnu-cc
#echo "gcc version"
#g++ --version
#echo "gcc test"
#x86_64-conda_cos6-linux-gnu-gcc -v test.c 
#echo "g++ test"
#x86_64-conda_cos6-linux-gnu-g++ -v test.c 
#export EXTRA_CONFIGURE_OPTS=" --with-gcc=$BUILD_PREFIX/bin/x86_64-conda_cos6-linux-gnu-cc --extra-include-dirs=$PREFIX/include --extra-lib-dirs=$PREFIX/lib $EXTRA_CONFIGURE_OPTS";
export EXTRA_CONFIGURE_OPTS=" --extra-include-dirs=$PREFIX/include --extra-lib-dirs=$PREFIX/lib $EXTRA_CONFIGURE_OPTS";
#sed -i -- 's/${GHC} --make ${JOBS} ${PKG_DBS} Setup -o Setup/${GHC} -optl " -lgmp" -pgmc ${CC} -pgml ${LD} --make ${JOBS} ${PKG_DBS} Setup -o Setup/g' cabal-install/bootstrap.sh
#echo "which ld"
#which ld

#which gcc
ghc-pkg recache
cd cabal-install
echo "Extra configure opts"
echo "$EXTRA_CONFIGURE_OPTS"
sed -i -- 's/args="$args ${EXTRA_CONFIGURE_OPTS} ${VERBOSE}"/args="$args ${EXTRA_CONFIGURE_OPTS} ${VERBOSE}"\n echo -e "$args"\n/g' bootstrap.sh
export GHC=`which ghc`
strings $GHC
./bootstrap.sh --no-doc
