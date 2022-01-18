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
