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
