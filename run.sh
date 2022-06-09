#!/bin/bash
# ./run.sh
# ./run.sh gui
# ./run.sh gui -debug=researcher

params=""
if [[ $1 == -* ]] ; then
	params="$params $1"
fi
if [[ $2 == -* ]] ; then
	params="$params $2"
fi
if [[ $3 == -* ]] ; then
	params="$params $3"
fi
if [[ $4 == -* ]] ; then
	params="$params $4"
fi
if [[ $5 == -* ]] ; then
	params="$params $5"
fi

echo "Parameters to transfer to Bitcoin: \"$params\""
#exit 1

if [ ! -d "src" ] ; then
	cd .. # If located in src or any other level of depth 1, return
fi

pruned="false"
if [ -d "/media/sf_Primecoin/blocks/" ] && [ ! -f "/media/sf_Primecoin/primecoind.pid" ] ; then
	dir="/media/sf_Primecoin"

# 5k full node
elif [ -d "/media/ubuntu1/Blockchains/Primecoin/blocks/" ] && [ ! -f "/media/ubuntu1/Blockchains/Primecoin/primecoind.pid" ] ; then
	dir="/media/ubuntu1/Blockchains/Primecoin"


# For running multiple nodes on the same machine
elif [ -d "$HOME/.primecoin/blocks/" ] && [ -f "$HOME/.primecoin/primecoind.pid" ] && 
	 [ -d "$HOME/.primecoin2/blocks/" ] && [ ! -f "$HOME/.primecoin2/primecoind.pid" ] ; then
	dir="$HOME/.primecoin2"
	pruned="true"
elif [ -d "$HOME/.primecoin/blocks/" ] && [ -f "$HOME/.primecoin/primecoind.pid" ] && 
	 [ -d "$HOME/.primecoin2/blocks/" ] && [ -f "$HOME/.primecoin2/primecoind.pid" ] && 
	 [ -d "$HOME/.primecoin3/blocks/" ] && [ ! -f "$HOME/.primecoin3/primecoind.pid" ] ; then
	dir="$HOME/.primecoin3"
	pruned="true"
elif [ -d "$HOME/.primecoin/blocks/" ] && [ -f "$HOME/.primecoin/primecoind.pid" ] && 
	 [ -d "$HOME/.primecoin2/blocks/" ] && [ -f "$HOME/.primecoin2/primecoind.pid" ] && 
	 [ -d "$HOME/.primecoin3/blocks/" ] && [ -f "$HOME/.primecoin3/primecoind.pid" ] && 
	 [ -d "$HOME/.primecoin4/blocks/" ] && [ ! -f "$HOME/.primecoin4/primecoind.pid" ] ; then
	dir="$HOME/.primecoin4"
	pruned="true"

else
	dir="$HOME/.primecoin"
	pruned="true"

	if [ ! -d "$dir" ] ; then
		mkdir "$dir"
	fi
fi

if [ -f "$dir/primecoind.pid" ] ; then
	echo "The directory \"$dir\" has primecoind.pid, meaning that Bitcoin is already running. In order to ensure that the blockchain does not get corrupted, the program will now terminate."
	exit 1
fi

echo "datadir = $dir"

rpcport=9910
port=9911
echo "Checking ports..."
while [[ $(lsof -i:$port) ]] | [[ $(lsof -i:$rpcport) ]]; do
	echo "port: $port, rpcport: $rpcport, ALREADY CLAIMED"
	rpcport=$((rpcport+2))
	port=$((port+2))
done
echo "port: $port, rpcport: $rpcport, SELECTED"

if [ ! -f "$dir/primecoin.conf" ] ; then #| [ port != 9911 ] ; then
	echo "Resetting configuration file"
	echo "server=1" > "$dir/primecoin.conf"
	echo "rpcuser=cybersec" >> "$dir/primecoin.conf"
	echo "rpcpassword=kZIdeN4HjZ3fp9Lge4iezt0eJrbjSi8kuSuOHeUkEUbQVdf09JZXAAGwF3R5R2qQkPgoLloW91yTFuufo7CYxM2VPT7A5lYeTrodcLWWzMMwIrOKu7ZNiwkrKOQ95KGW8kIuL1slRVFXoFpGsXXTIA55V3iUYLckn8rj8MZHBpmdGQjLxakotkj83ZlSRx1aOJ4BFxdvDNz0WHk1i2OPgXL4nsd56Ph991eKNbXVJHtzqCXUbtDELVf4shFJXame" >> "$dir/primecoin.conf"
	echo "port=$port" >> "$dir/primecoin.conf"
	echo "rpcport=$rpcport" >> "$dir/primecoin.conf"
	#echo "rpcallowip=0.0.0.0/0" >> "$dir/primecoin.conf"
	#echo "rpcbind = 0.0.0.0:9910" >> "$dir/primecoin.conf"
	#echo "upnp=1" >> "$dir/primecoin.conf"
	echo "listen=1" >> "$dir/primecoin.conf"
fi

if [ "$1" == "gui" ] ; then
	if [ "$pruned" == "true" ] ; then
		echo "Pruned mode activated, only keeping 550 block transactions"
		echo
		src/qt/bitcoin-qt -prune=550 -datadir="$dir" $params #-debug=researcher
	else
		echo
		src/qt/bitcoin-qt -datadir="$dir" $params #-debug=researcher
	fi
else

	# Only open the console if not already open
	if ! wmctrl -l | grep -q "Custom Primecoin Console" ; then
		# Find the right terminal
		if [ -x "$(command -v mate-terminal)" ] ; then
			mate-terminal -t "Custom Primecoin Console" -- python3 primecoin_console.py
		elif [ -x "$(command -v xfce4-terminal)" ] ; then
			xfce4-terminal -t "Custom Primecoin Console" -- python3 primecoin_console.py
		else
			gnome-terminal -t "Custom Primecoin Console" -- python3 primecoin_console.py
		fi
	fi

	if [ "$pruned" == "true" ] ; then
		echo "Pruned mode activated, only keeping 550 block transactions"
		echo
		src/primecoind -printtoconsole -prune=550 -datadir="$dir" $params #-debug=researcher
	else
		echo
		src/primecoind -printtoconsole -datadir="$dir" $params #-debug=researcher
		# Reindexing the chainstate:
		#src/primecoind -datadir="/media/sf_Bitcoin" -debug=researcher -reindex-chainstate
	fi
fi
