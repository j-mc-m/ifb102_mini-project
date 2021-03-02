# Copyright 2019 Jack Muir (j_mc_m), under GPL V3+
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

#!/bin/bash

usage() {
    echo "$0 <seconds to record for> <interface>"
    exit
}

func() {
    limit=$1
    timer=$2
    net=$3

    while [ $limit != $timer ]; do
	if [ $timer == 0 ]; then
	    echo "Starting iftop..."
	    iftop -t -B -i $net | tee /tmp/net_traffic &
	fi

	((timer += 1))
	echo $timer
	sleep 1
    done

    sleep 1
    echo "Killing iftop..."
    killall iftop
}

if [ $EUID -ne 0 ]; then
    echo "Not running as root..."
else
    if [ $(echo $@ | wc -w) != 2 ]; then
		usage
    fi

    echo "========================================================"
    echo " ___ _____ ____  _  ___ ____  			  "
    echo "|_ _|  ___| __ )/ |/ _ \___ \ 			  "
    echo " | || |_  |  _ \| | | | |__) |			  "
    echo " | ||  _| | |_) | | |_| / __/ 			  "
    echo "|___|_|   |____/|_|\___/_____|			  "
    echo " __  __ _       _       ____            _           _   "
    echo "|  \/  (_)_ __ (_)     |  _ \ _ __ ___ (_) ___  ___| |_ "
    echo "| |\/| | | '_ \| |_____| |_) | '__/ _ \| |/ _ \/ __| __|"
    echo "| |  | | | | | | |_____|  __/| | | (_) | |  __/ (__| |_ "
    echo "|_|  |_|_|_| |_|_|     |_|   |_|  \___// |\___|\___|\__|"
    echo "                                     |__/               "
    echo "========================================================"

    if [ $(pgrep -x tor) ]; then
	echo "Tor process already running. Skipping..."
    else
	echo "Starting Tor daemon..."
	chown -R root:root /var/lib/tor
	chown -R root:root /var/lib/tor/*
	tor > /dev/null
    fi	

    timer=$1
    net=$2

    sleep 1

    echo "Now recording for $timer seconds..."
    func $timer 0 $net

    echo "Generating graphs..."
    ./moni-tor.sh /tmp/net_traffic both /srv/http
    echo "Graphs generated."

    echo "Starting lighttpd service (if not already running)..."
    systemctl start lighttpd
fi
