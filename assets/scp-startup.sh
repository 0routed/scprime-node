#!/bin/bash
#johndoe220209

touch .scprime/startuplog
echo '--#-#-#--' | tee -a .scprime/startuplog
echo $(date "+%Y-%m-%d_%H:%M:%S.%N") ': startupscript...' | tee -a .scprime/startuplog

#to speedup the initial setup, if there is no consensus.db the latest version is downloaded from https://consensus.scpri.me/releases/consensus-latest.zip
if [ ! -e ~/.scprime/consensus/consensus.db ];
then
   echo $(date "+%Y-%m-%d_%H:%M:%S.%N") ': no consensus.db found... bootstrapping. download can take a few minutes.' | tee -a .scprime/startuplog
   mkdir ~/.scprime/consensus
   curl https://consensus.scpri.me/releases/consensus-latest.zip --output ~/.scprime/consensus/latest.zip
   echo $(date "+%Y-%m-%d_%H:%M:%S.%N") ': download done. unpacking.' | tee -a .scprime/startuplog
   unzip ~/.scprime/consensus/latest.zip -d ~/.scprime/consensus/ | tee -a .scprime/startuplog
   rm ~/.scprime/consensus/latest.zip
fi

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
