cd src ; make -f makefile.unix

cd ..
qmake BITCOIN_QT_TEST=1 -o Makefile.test bitcoin-qt.pro
make -f Makefile.test

./run.sh