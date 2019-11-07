# Elrond Node deploy scripts V2

## Preliminary instructions

* Scripts Structure:
variables.cfg - location for custom local & remote system variables 
functions.cfg - all functions used in main script body are placed here
script.sh - main script

* Mandatory things to add:
.identity - specify PEM (for remote machines) location here:
```
PEM="~/.ssh/id_rsa"
```
target_ips - add all of your remote machines ips here with newline after each one

## Script functions

* First time install:
 - ./script.sh install --> single node local machine install
 - ./script.sh install_hosts --> install node on multiple hosts (using target_ips file)

* Update/upgrade node:
 - ./script.sh upgrade --> upgrade a single local node 
 - ./script.sh upgrade_hosts --> upgrade node on all hosts (using target_ips file)

* Start nodes:
 - sudo systemctl start elrond-node.service --> Start your local node
 - ./script.sh start_hosts --> start node process on all hosts (using target_ips file)

