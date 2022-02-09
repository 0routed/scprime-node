#!/bin/bash

#adjust as needed
NODENAME=SCP0X # nodename for the container
HA=8282 #will be passed to spd in the container --host-addr :$HA
SA=8283 #will be passed to spd in the container --siamux-addr :$SA
HAA=8285 #will be passed to spd in the container --host-api-addr :$HAA
SCVERSION=1.6.0 #choose version of spd - only tested with 1.6.0
SCTIMEZONE=Europe/Berlin # set your timezone at buildtime

docker build --pull --build-arg SCVERSION=$SCVERSION --build-arg SETTZ=$SCTIMEZONE  --rm -f "Dockerfile" -t local/scprime-node:1.0-$SCVERSION "." # comment out this line if you just need an additional container

docker run -dt \
 -v /path/on/host/to/metadata:/home/appuser/.scprime \
 -v /path/on/host/to/storage:/mnt/storage \
 -p $HA:$HA \
 -p $SA:$SA \
 -p $HAA:$HAA \
 -e HA=$HA \
 -e SA=$SA \
 -e HAA=$HAA \
 --name $NODENAME \
 --memory=4096mb \
 --cpus=3 \
 --restart unless-stopped\
 local/scprime-node:1.0-$SCVERSION
