#!/bin/bash

set -eu

DOCKER_IMAGE=freekkalter/ovpn
OVPN_DATA=${OVPN_DATA:-ovpn-data}

# build latest image
build_image() {
    cd /home/fkalter/docker-openvpn/
    docker build --pull --tag $DOCKER_IMAGE .
    cd -
}

# Create vpn configs and keys on a seperate docker volume
create_configs_and_keys() {
    docker volume create --name $OVPN_DATA
    docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm $DOCKER_IMAGE  ovpn_genconfig -u udp://vpn.kalteronline.org
    docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm -it $DOCKER_IMAGE ovpn_initpki
}

# create client key
create_client() {
    client_name=$1
    docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm -it $DOCKER_IMAGE  easyrsa --keysize=4096 build-client-full $client_name nopass
    docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm $DOCKER_IMAGE ovpn_getclient $client_name > $client_name.ovpn
}

# backup data volume
backup() {
    docker run --rm -v $OVPN_DATA:/etc/openvpn -v $(pwd):/backup ubuntu tar cvf /backup/backup.tar /etc/openvpn
}

usage() {
    echo "usage: $0 "
    echo " -b                       build freekkalter/ovpn, updating all packages needed"
    echo " -c                       Create the $OVPN_DATA volume, initialize with server configs, keys and certificates"
    echo " -C       CLIENTNAME      Create client certificate and key and write to a CLIENTNAME.ovpn file for usage by client app"
    echo " -B                       Backup $OVPN_DATA volume to a tar file"
    echo " -a       CLIENTNAME      Do all of the above, takes clientname as argument like -C"
}

while getopts "a:bcC:Bh" opt; do
    case $opt in
        a)
            echo "doing it all"
            build_image
            create_configs_and_keys
            create_client $OPTARG
            backup
            exit
            ;;
        b)
            echo "build image"
            build_image
            ;;
        c)
            echo "create configs and keys"
            create_configs_and_keys
            ;;
        C)
            echo "create client $OPTARG.ovpn file"
            create_client $OPTARG
            ;;
        B)
            echo "backup"
            backup
            ;;
        h)
            usage
            exit
            ;;
        \?)
            usage
            exit
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            exit
            ;;
    esac
done
