# Elrond Node deploy scripts V2

## Preliminary instructions

#### Scripts Structure:
- variables.cfg - location for custom local & remote system variables 
- functions.cfg - all functions used in main script body are placed here
- script.sh - main script

#### Mandatory things to add:
- variables.cfg - here you must specify home folder path and user name for the remote machines
- target_ips - add all of your remote machines ips here with newline after each one
- .identity - specify PEM (for remote machines) location here:
```
PEM="<PATH TO YOUR SERVER ACCESS KEY>/<ACCESS KEY NAME>"
```

#### Optional things to add:
- You can provide your own node keys at the install stage by placing them in this path:
```
<HOME-FOLDER-PATH>/VALIDATOR_KEYS/node-0/
<HOME-FOLDER-PATH>/VALIDATOR_KEYS/node-1/
.
.
.
<HOME-FOLDER-PATH>/PEMS/node-x/
```

## Script functions

#### First time install:
 - ./script.sh install --> single or multiple nodes local machine install
 - ./script.sh install_hosts --> install nodes on multiple hosts (using target_ips file)

#### Update/upgrade node:
 - ./script.sh upgrade --> upgrade a single or multiple local nodes 
 - ./script.sh upgrade_hosts --> upgrade nodes on all hosts (using target_ips file)

#### Start nodes:
 - ./script.sh start --> Start your local node or nodes
 - ./script.sh start_hosts --> start node processes on all hosts (using target_ips file)

