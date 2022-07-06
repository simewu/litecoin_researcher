# cd src ; make -f makefile.unix

# cd ..
# qmake BITCOIN_QT_TEST=1 -o Makefile.test bitcoin-qt.pro
# make -f Makefile.test

make -j8
make install

./run.sh