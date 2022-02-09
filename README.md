# scprime-node
Dockerfile for ScPrime storage provider node.

1.0-1.6.0, 20220209

*see https://scpri.me for projectdetails.*

### THIS IS NOT AN OFFICIAL SCPRIME DOCKERIMAGE. COMES AS IS, NO WARRANTY, YADAYADA... DO YOUR OWN DUE DILIGENCE ###

- ## **v1.0**-1.6.0 _"yay, it didn't catch on fire"_
  - startupscript: added auto-bootstrapping for the consensus.db for faster setup
  - new tagging: `nullrouted/scprime-node`:`image-version`-`scprime-version` => nullrouted/scprime-node:1.0-1.6.0
 
 ---
 
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



#### dockerimage available on https://hub.docker.com/r/nullrouted/scprime-node/
