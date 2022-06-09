sudo apt-get -y update

# Bitcoin dependencies
sudo apt-get -y install build-essential libtool autotools-dev automake pkg-config bsdmainutils python3
# Build with self-compiled depends to re-enable wallet compatibility
sudo apt-get -y install libssl-dev libevent-dev libboost-all-dev

# GUI dependencies
sudo apt-get -y install libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler
sudo apt-get -y install libqrencode-dev

# Bitcoin wallet functionality
sudo apt-get -y install libdb-dev libdb++-dev

# Incoming connections
sudo apt-get -y install libminiupnpc-dev

# Used to check what windows are open
sudo apt-get -y install wmctrl

# Potentially redundant primecoin specifications
sudo apt-get install build-essential
sudo apt-get install -y build-essential autoconf libtool pkg-config libboost-all-dev libssl-dev libevent-dev libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler libqrencode-dev libminiupnpc-dev curl


#./autogen.sh
#./configure --with-miniupnpc --enable-upnp-default --with-incompatible-bdb # --disablewallet # --prefix=`pwd`/depends/x86_64-linux-gnu
#./configure --without-miniupnpc --enable-upnp-default --with-incompatible-bdb # --disablewallet # --prefix=`pwd`/depends/x86_64-linux-gnu

cd depends; make
export BOOST_INCLUDE_PATH=`pwd`/x86_64-pc-linux-gnu/include
export BDB_INCLUDE_PATH=`pwd`/x86_64-pc-linux-gnu/include
export OPENSSL_INCLUDE_PATH=`pwd`/x86_64-pc-linux-gnu/include
export BOOST_LIB_PATH=`pwd`/x86_64-pc-linux-gnu/lib
export BOOST_LIB_SUFFIX=-mt
cd ..
cd src ; make -f makefile.unix USE_UPNP:=

#make -j8
qmake BITCOIN_QT_TEST=1 -o Makefile.test bitcoin-qt.pro
make -f Makefile.test

cd ..
./run.sh
