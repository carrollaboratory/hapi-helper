# hapi-helper
Docker compose and helper script for local FHIR validation 

# Usage
This assumes you are have docker compose running on your system: 

```bash
docker compose up -d
```
This will bring the server up in detached mode

```bash
docker compose logs -f fhir 
``` 
This will let you inspect the logs from your current shell

```bash 
docker compose down -v
```
If you need to blow things away. In general, the database will persist between 
restarts (leave off the -v to just shut the machine down without destroying the 
image), but sometimes it helps to start over again

# Load IG Script
If you want to load an updated version of the IG or load a different IG in 
addition to the NCPI IG, you can use the included script, scripts/load_ig.sh

## Loading an IG
This script isn't particularly sophisticated, so no authentication is currently
supported. But it's good enough to update the IG on your laptop's validation
server: 

```bash
scripts/load_ig.sh [server] [IG]
```
The arguments, server and IG are both optional, but they are positional. So, if 
you want to specify the IG you want to load, you also MUST provide the server 
as well. By default the following are use: 
* server  - http://localhost:8080/fhir
* IG - https://nih-ncpi.github.io/ncpi-fhir-ig-2/package.tgz

Note that you provide the full BASE URL for the FHIR server REST API. For HAPI, 
by default, it will be server/fhir but that is probably configurable. 

For the IG, you must provide the full URL for the package tarball.
