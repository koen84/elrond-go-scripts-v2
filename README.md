# Elrond Node deploy scripts V2

## Preliminary instructions
- The current version of scripts allow you to run multiple nodes locally or multiple nodes on multiple remote machines.
- It relies on SSH (using key pairs) and on RSYNC through SSH
- The nodes will run in the backround as separate systemd units.
- This scripts package requires that the user they are run under has the ability to run sudo commands.

#### Scripts Structure:
- configs/variables.cfg - location for custom local & remote system variables 
- configs/functions.cfg - all functions used in main script body are placed here
- script.sh - main script

#### Mandatory things to add:
- variables.cfg - here you must specify the home folder path and user name for the remote machines and you have the option to use a custom port for ssh
- target_ips - create this file inside the scripts folder abd add all of your remote machines ips inside (with newline after each one)
- .identity - create this file inside the scripts configs folder and add your PEM (ssh keys) name and path using this format:
```
PEM="<PATH TO YOUR SERVER ACCESS KEY>/<ACCESS KEY NAME>"
```

#### Validator Keys Management:
- If you have custom validator keys for your nodes the script looks for them in the "<HOME-FOLDER-PATH>/VALIDATOR_KEYS/" folder on each machine
- The install script expects the keys in zip format follwing this naming pattern:

```
<HOME-FOLDER-PATH>/VALIDATOR_KEYS/node-0.zip
<HOME-FOLDER-PATH>/VALIDATOR_KEYS/node-1.zip
.
.
.
<HOME-FOLDER-PATH>/VALIDATOR_KEYS/node-x.zip
```

- If there are not enough keys for all nodes on a specific machine new keys will be automatically generated (but those nodes will only be observers)

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
 
#### Start nodes:
 - ./script.sh stop --> Start your local node or nodes
 - ./script.sh stop_hosts --> start node processes on all hosts (using target_ips file)