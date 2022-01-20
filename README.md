# scprime-node
Dockerfile for ScPrime storage provider node.

1.0-rc3, 20220118

*see https://scpri.me for projectdetails.*

### THIS IS NOT AN OFFICIAL SCPRIME DOCKERIMAGE. COMES AS IS, NO WARRANTY, YADAYADA... DO YOUR OWN DUE DILIGENCE ###
- **`spd` runs as unprivileged user `appuser:appuser`** (`789:789`) inside the container (based on _ubuntu:20.04_).
- by **default ports `4282 4283 4285`** are exposed.
 - supply you own with `docker run ...  -p 5282:5282 -e HA=5282 -p 5283:5283 -e SA=5283 -p 5285:5285 -e HAA=5285 ...` (if i only change the portnumber exposed to the host the grafana dashboard is sad and says port error therefore we need to change internal and external ports and pass the changed port to `spd` as well with an ENV supplied by `-e ENV=...`)
- **metadata is stored in `/home/appuser/.scprime/`** inside the container - mount your host folder there. `docker run ... -v /path/on/host/to/metadata:/home/appuser/.scprime ...` - and don't forget to backup your metadata from time to time... this is where your contracts life)
- i suggest you **mount your storage folder to `/mnt/storage`**. `docker run ... -v /path/on/host/to/storage:/mnt/storage ...`
- for testing you can leave out mounting host-volumes skipping on the `-v`'s in `docker run ...` - just remember to copy out whatever you need!
- create a file with your **walletpassword at `/home/appuser/.scprime/walletpassword`** to enable auto unlocking on start
 - auto unlock only works after consensus is ready (be patient on the first run - check `docker exec SCP0X spc consensus`) and wallet is initialized with `docker exec -it SCP0X spc wallet init` (or `init-seed` if you transfer over a wallet)
- make sure both the **`metadata` and `storage` folder ownership is set to `789:789` and permissions to `700`**
- launch a shell with `docker exec -it SCP0X /bin/bash` or **talk to `spc` directly with `docker exec -it SCP0X spc YOUR COMMAND`**
 - `spd` startup is logged to `docker logs SCP0X` and `/home/appuser/.scprime/startuplog` (so in your metadata folder)
- the image on hub.docker.com is `amd64` only, the Dockerfile does work on `arm64` too and automatically downloads the `arm64` binary for `spd`
 - ***but remember:*** rpi and sbc support has been dropped... 
- *the downloaded `spd` binaries are somewhat verified* on buildtime with the supplied pubkey and signature.. but they come from the same downloadserver. #pinchofsalt
- i have successfully moved instance-data between different nodes and switching from "normal" installations to docker containers during testing, make backups, try stuff.
- as you are **storing an unlocked wallet in the container, keep it updated!** obviously keep the host up to date as well!
 - easiest way ist to just rebuild the container with `docker stop SCP0X && docker container rm SCP0X && sh spinup.sh`. it will get the latest `ubunut:20.04` base image and the build runs `apt-get update`. given the same parameters for ports and path your container should be up and running in no time without interaction. check `docker logs CONTAINRTNAME` to verify.
 - for `spd` i will try to update this image or you can change the version in the `spinup.sh` script below.



#### dockerimage available on https://hub.docker.com/r/nullrouted/scprime-node/tags

my buildscript **`spinup.sh`**
```
#!/bin/bash

#adjust as needed
NODENAME=SCP0X # nodename for the container
HA=8282 #will be passed to spd in the container --host-addr :$HA
SA=8283 #will be passed to spd in the container --siamux-addr :$SA
HAA=8285 #will be passed to spd in the container --host-api-addr :$HAA
SCVERSION=1.6.0 #choose version of spd - only tested with 1.6.0
SCTIMEZONE=Europe/Berlin # set your timezone at buildtime

docker build --pull --build-arg SCVERSION=$SCVERSION --build-arg SETTZ=$SCTIMEZONE  --rm -f "Dockerfile" -t local/scprime-node:$SCVERSION "." # comment out this line if you just need an additional container

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
 --cpus=3 \
 --restart unless-stopped\
 local/scprime-node:$SCVERSION
```

my **`Dockerfile`**
```
FROM ubuntu:20.04

LABEL version='1.0-rc3'
LABEL date='20220118'
LABEL maintainer='johndoe'
LABEL contact='docker@nullrouted.link'

#SPECIFY WHICH VERSION OF SCPRIME TO DOWNLOAD
ARG SCVERSION=1.6.0

#SPECIFY YOUR TIMEZONE
ARG SETTZ=Europe/Berlin

#SPECIFY DEFAULT PORTS
ENV HA 4282
ENV SA 4283
ENV HAA 4285

#JUST A FILLER, PASSWORD WILL BE LOADED FROM DISK
ENV SCPRIME_WALLET_PASSWORD=YOUDIDNOTPROVIDEAPASSWORD

#SETUP
RUN apt-get -qq -y update&&\
    apt-get -qq -y upgrade&&\
    apt-get -qq -y install unzip curl gnupg tzdata nano

#RUN ln -snf /usr/share/zoneinfo/${SETTZ} /etc/localtime && echo ${SETTZ} > /etc/timezone

RUN mkdir -p /home/appuser/.scprime

COPY ./assets/scp-startup.sh /home/appuser/startup.sh

#INSTALL SCPRIME, DEFINE YOUR VERSION AT THE TOP
#SHA256 checksum of the pubkey at https://releases.scpri.me/scprime_pub_key.asc is f6569c5c6966761493ca997a3ebe5d47889cbc194c15ffbbaf02f870044f7d88 as per 2022-01-17 (bit hacky, but i coudln't find the pubkey stored in on a _separate_ server than the downloadserver so i check if at least the keys checksum is the same as when i built the image.)

WORKDIR /tmp/
RUN export INSTALLARCH=$(dpkg --print-architecture)&&\
    curl --silent https://releases.scpri.me/scprime_pub_key.asc --output pubkey.asc  &&\
    curl --silent https://releases.scpri.me/${SCVERSION}/ScPrime-v${SCVERSION}-linux-$INSTALLARCH.zip --output scp.zip  &&\
    curl --silent https://releases.scpri.me/${SCVERSION}/ScPrime-v${SCVERSION}-linux-$INSTALLARCH.zip.asc --output scp.asc  &&\
    echo 'f6569c5c6966761493ca997a3ebe5d47889cbc194c15ffbbaf02f870044f7d88  pubkey.asc' > refsum &&\
    if sha256sum -c refsum ; \
        then \
         gpg -q --always-trust --import pubkey.asc&&gpg -q --verify scp.asc scp.zip&&unzip -j scp.zip ScPrime-v$SCVERSION-linux-$INSTALLARCH/spc ScPrime-v$SCVERSION-linux-$INSTALLARCH/spd -d /usr/bin && rm /tmp/* ; \
        else \
         echo 'pubkey verification failed. removing downloads. installation failed.'&& rm ./* && exit 1 ; \
    fi

#CLEANING UP PERMISSIONS
RUN groupadd -g 789 appuser && \
    useradd -r -u 789 -g appuser appuser

RUN chown -R appuser:appuser /home/appuser &&\
    chmod -R 700 /home/appuser

#SWITCHING TO UNPRIVILEGED USER
USER appuser

WORKDIR /home/appuser/

ENTRYPOINT ["/bin/bash","-c","~/startup.sh"]
```

my startup script `./assets/scp-startup.sh` that will be copied to the container at buildtime
```
#!/bin/bash
#johndoe220117

touch .scprime/startuplog
echo '--#-#-#--' | tee -a .scprime/startuplog
echo $(date "+%Y-%m-%d_%H:%M:%S.%N") ': startupscript...' | tee -a .scprime/startuplog

#if there is a walletpassword it is loaded as environmentvariable to auto-unlock the wallet (spd only attemps auto-unlock when consensus is fully synced, takes a long time on first setup!!!)
if [ -e .scprime/walletpassword ];
then
   echo $(date "+%Y-%m-%d_%H:%M:%S.%N") ': walletpassword found' | tee -a .scprime/startuplog
   export SCPRIME_WALLET_PASSWORD=`cat .scprime/walletpassword`
else
   echo $(date "+%Y-%m-%d_%H:%M:%S.%N") ': walletpassword not found.' | tee -a .scprime/startuplog
fi

#if there is a apipassword it is loaded as environmentvariable
if [ -e .scprime/apipassword ];
then
   echo $(date "+%Y-%m-%d_%H:%M:%S.%N") ': apipassword found' | tee -a .scprime/startuplog
   export SCPRIME_API_PASSWORD=`cat .scprime/apipassword`
else
   echo $(date "+%Y-%m-%d_%H:%M:%S.%N") ': apipassword not found.' | tee -a .scprime/startuplog
fi



echo $(date "+%Y-%m-%d_%H:%M:%S.%N") ': spd -M gctwh --host-addr :'$HA' --siamux-addr :'$SA' --host-api-addr :'$HAA | tee -a .scprime/startuplog
spd -M gctwh --host-addr :$HA --siamux-addr :$SA --host-api-addr :$HAA 2>&1 | tee -a .scprime/startuplog

echo $(date "+%Y-%m-%d_%H:%M:%S.%N") ': end.' | tee -a .scprime/startuplog
```

