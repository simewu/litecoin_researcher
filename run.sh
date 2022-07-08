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
if [ -d "/media/sf_Litecoin/blocks/" ] && [ ! -f "/media/sf_Litecoin/litecoind.pid" ] ; then
	dir="/media/sf_Litecoin"

# 5k full node
elif [ -d "/media/ubuntu1/Blockchains/Litecoin/blocks/" ] && [ ! -f "/media/ubuntu1/Blockchains/Litecoin/litecoind.pid" ] ; then
	dir="/media/ubuntu1/Blockchains/Litecoin"


# For running multiple nodes on the same machine
elif [ -d "$HOME/.litecoin/blocks/" ] && [ -f "$HOME/.litecoin/litecoind.pid" ] && 
	 [ -d "$HOME/.litecoin2/blocks/" ] && [ ! -f "$HOME/.litecoin2/litecoind.pid" ] ; then
	dir="$HOME/.litecoin2"
	pruned="true"
elif [ -d "$HOME/.litecoin/blocks/" ] && [ -f "$HOME/.litecoin/litecoind.pid" ] && 
	 [ -d "$HOME/.litecoin2/blocks/" ] && [ -f "$HOME/.litecoin2/litecoind.pid" ] && 
	 [ -d "$HOME/.litecoin3/blocks/" ] && [ ! -f "$HOME/.litecoin3/litecoind.pid" ] ; then
	dir="$HOME/.litecoin3"
	pruned="true"
elif [ -d "$HOME/.litecoin/blocks/" ] && [ -f "$HOME/.litecoin/litecoind.pid" ] && 
	 [ -d "$HOME/.litecoin2/blocks/" ] && [ -f "$HOME/.litecoin2/litecoind.pid" ] && 
	 [ -d "$HOME/.litecoin3/blocks/" ] && [ -f "$HOME/.litecoin3/litecoind.pid" ] && 
	 [ -d "$HOME/.litecoin4/blocks/" ] && [ ! -f "$HOME/.litecoin4/litecoind.pid" ] ; then
	dir="$HOME/.litecoin4"
	pruned="true"

else
	dir="$HOME/.litecoin"
	pruned="true"

	if [ ! -d "$dir" ] ; then
		mkdir "$dir"
	fi
fi

if [ -f "$dir/litecoind.pid" ] ; then
	echo "The directory \"$dir\" has litecoind.pid, meaning that Bitcoin is already running. In order to ensure that the blockchain does not get corrupted, the program will now terminate."
	exit 1
fi

echo "datadir = $dir"

rpcport=9432
port=9432
echo "Checking ports..."
while [[ $(lsof -i:$port) ]] | [[ $(lsof -i:$rpcport) ]]; do
	echo "port: $port, rpcport: $rpcport, ALREADY CLAIMED"
	rpcport=$((rpcport+2))
	port=$((port+2))
done
echo "port: $port, rpcport: $rpcport, SELECTED"

if [ ! -f "$dir/litecoin.conf" ] ; then #| [ port != 9911 ] ; then
	echo "Resetting configuration file"
	echo "server=1" > "$dir/litecoin.conf"
	echo "rpcuser=cybersec" >> "$dir/litecoin.conf"
	echo "rpcpassword=kZIdeN4HjZ3fp9Lge4iezt0eJrbjSi8kuSuOHeUkEUbQVdf09JZXAAGwF3R5R2qQkPgoLloW91yTFuufo7CYxM2VPT7A5lYeTrodcLWWzMMwIrOKu7ZNiwkrKOQ95KGW8kIuL1slRVFXoFpGsXXTIA55V3iUYLckn8rj8MZHBpmdGQjLxakotkj83ZlSRx1aOJ4BFxdvDNz0WHk1i2OPgXL4nsd56Ph991eKNbXVJHtzqCXUbtDELVf4shFJXame" >> "$dir/litecoin.conf"
	echo "port=$port" >> "$dir/litecoin.conf"
	echo "rpcport=$rpcport" >> "$dir/litecoin.conf"
	#echo "rpcallowip=0.0.0.0/0" >> "$dir/litecoin.conf"
	#echo "rpcbind = 0.0.0.0:9910" >> "$dir/litecoin.conf"
	#echo "upnp=1" >> "$dir/litecoin.conf"
	echo "listen=1" >> "$dir/litecoin.conf"
	echo "maxconnections=1000" >> "$dir/litecoin.conf"
fi

if [ "$1" == "gui" ] ; then
	if [ "$pruned" == "true" ] ; then
		echo "Pruned mode activated, only keeping 550 block transactions"
		echo
		src/qt/litecoin-qt -prune=550 -datadir="$dir" $params #-debug=researcher
	else
		echo
		src/qt/litecoin-qt -datadir="$dir" $params #-debug=researcher
	fi
else

	# Only open the console if not already open
	if ! wmctrl -l | grep -q "Custom Litecoin Console" ; then
		# Find the right terminal
		if [ -x "$(command -v mate-terminal)" ] ; then
			mate-terminal -t "Custom Litecoin Console" -- python3 litecoin_console.py
		elif [ -x "$(command -v xfce4-terminal)" ] ; then
			xfce4-terminal -t "Custom Litecoin Console" -- python3 litecoin_console.py
		else
			gnome-terminal -t "Custom Litecoin Console" -- python3 litecoin_console.py
		fi
	fi

	if [ "$pruned" == "true" ] ; then
		echo "Pruned mode activated, only keeping 550 block transactions"
		echo
		src/litecoind -printtoconsole -prune=550 -datadir="$dir" $params #-debug=researcher
	else
		echo
		src/litecoind -printtoconsole -datadir="$dir" $params #-debug=researcher
		# Reindexing the chainstate:
		#src/litecoind -datadir="/media/sf_Bitcoin" -debug=researcher -reindex-chainstate
	fi
fi
