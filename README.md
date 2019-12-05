# Elrond Node Deploy Scripts V2

## INTRODUCTION

The current scripts version aims to bring the validator experience closer to mainnet levels and also implements an optional auto update feature.
Following a few simple steps, you can run your node(s) both on local machine and/or multiple remote machines, relying on SSH and RSYNC.
Each node will run in background as a separate systemd unit.


## REQUIREMENTS

- Running Ubuntu 18.04 & up
- Running the script requires sudo priviledges (without password).
- Remote machines should be accesible via SSH using key pairs.

## SCRIPT SETTINGS - MUST BE MODIFIED BEFORE FIRST RUN

- config/variables.cfg - used to define username, home path, keys location and SSH port.
- config/identity 	   - used to define the path to the SSH key - <MAKE SURE YOU EDIT THIS FILE TO MATCH YOUR SETUP!>
- config/target_ips    - used to define the list of remote machines (IPs or hostnames), each machine in a new line

## KEY MANAGEMENT

Each machine must have its own key set(s) copied locally. 
For running only one node per machine, the 2 keys (initialBalancesSk.pem and initialNodesSk.pem) should be placed in a zip file named 'node-0.zip', in the path previously specified in variables.cfg file (NODE_KEYS_LOCATION). 
Note: "$NODE_KEYS_LOCATION" is created from "$CUSTOM_HOME" and the folder "VALIDATOR_KEYS" by default. 
For running additional nodes on the same machine, simply create additional zip files incrementing the numeric value (i.e. for second node: 'node-1.zip', for third node: 'node-2.zip', etc..), containing the additional key sets.

File structure example:

	$CUSTOM_HOME/VALIDATOR_KEYS/node-0.zip
	$CUSTOM_HOME/VALIDATOR_KEYS/node-1.zip
	$CUSTOM_HOME/VALIDATOR_KEYS/node-2.zip
	...
	$CUSTOM_HOME/VALIDATOR_KEYS/node-x.zip
	

If no key sets are found in the specified location, the script will generate new keys and the node(s) will run as Observer(s).
 
Example of adding your validator keys to a zip file (node-0.zip):
1. Navigate to your current node install path and go into the /config folder
2. Issue the command to create your zip archive: `zip node-0.zip *.pem` (repeat for each node on that machine incrementing the value 0,1,2...x)
3. Move the zip archive to the `$CUSTOM_HOME/VALIDATOR_KEYS` folder: `mv node-0.zip $CUSTOM_HOME/VALIDATOR_KEYS/` (repeat for all nodes on that machine)

## RUNNING THE SCRIPT

	[FIRST RUN]
		#installs the node(s) on the local machine
		./script.sh install 
		
		#installs the node(s) on all the machines specified in 'target_ips' file 
		./script.sh install-remote 
		
		Running the script with the 'install' or 'install-remote' parameter will prompt for each machine the following:
			- number of nodes to be ran on the machine
			- validator display name for each node (this will only be asked one time)
			- optionally enable the auto-update feature (default 'No') - see [AUTO UPDATE] section for more details	
			
	[UPGRADE]
		#upgrades the node(s) on the local machine
		./script.sh upgrade
		
		#upgrades the node(s) on all the machines specified in 'target_ips' file
		./script.sh upgrade-remote 
		
	[START]
		#starts the node(s) on the local machine
		./script.sh start
		
		#starts the node(s) on all the machines specified in 'target_ips' file
		./script.sh start-remote 
		
	[STOP]
		#stops the node(s) on the local machine
		./script.sh stop
		
		#stops the node(s) on all the machines specified in 'target_ips' file
		./script.sh stop-remote 
				
	[CLEANUP]
		#Removes all the node(s) files on the local machine
		./script.sh cleanup
		
		#Removes all the node(s) files on all the machines specified in 'target_ips' file
		./script.sh cleanup-remote 

## AUTO UPDATE

If you choose to enable this function, a cron job will be created. The job searches every 10 minutes for new releases.
You can check the status of the auto-update job in the file $HOME/autoupdate.status
If you haven't installed the updater function but you wish to do it afterwards you can do it bu running:

	[AUTO-UPDATER CRON]	
		#installs the auto-update cronjob on the local machine
		./script.sh crontab
		
		#installs the auto-update cronjob on all the machines specified in 'target_ips' file
		./script.sh crontab-remote 
		

## TERMUI NODE INFO

This version of scripts will start your nodes as separate systemd services and an additional termui binary will be build for you on each machine and placed in your $CUSTOM_HOME/elrond-utils folder.
This tool provides a console-graphical interface useful for providing node status in a user-friendly way. The binary will try to connect to the node over the rest API interface provided.
During the install process your nodes will have rest api sockets assigned to them following this pattern:

	elrond-node-0 will use localhost:8080
	elrond-node-1 will use localhost:8081
	elrond-node-2 will use localhost:8082
	...
	elrond-node-x will use localhost:(8080+x)
	

You can check the status of each of your nodes in turn by going to your $CUSTOM_HOME/elrond-utils/ folder and using this command (making sure you select the proper socket for the desired node):

	./elrond-utils/termui -address localhost:8080
	or
	./elrond-utils/termui -address localhost:8081
	...

## LOGVIEWER INFO

This version of scripts will start your nodes as separate systemd services and an additional logviewer binary will be build for you on each machine and placed in your $CUSTOM_HOME/elrond-utils folder.
This tool provides a way of capturing (and even storing) logger lines generated by an elrond-node instance. The binary will try to connect to the node over the rest API interface provided.
During the install process your nodes will have rest api sockets assigned to them following this pattern:

	elrond-node-0 will use localhost:8080
	elrond-node-1 will use localhost:8081
	elrond-node-2 will use localhost:8082
	...
	elrond-node-x will use localhost:(8080+x)
	

You can check the status of each of your nodes in turn by going to your $CUSTOM_HOME/elrond-utils/ folder and using this command (making sure you select the proper socket for the desired node):

	./elrond-utils/logviewer -address localhost:8080
	or
	./elrond-utils/logviewer -address localhost:8081
	...

If the log level is not provided, it will start with the `*:INFO` pattern, meaning that all subpackages that assemble the elrond-go binary will only output INFO (or up) messages.
There is another flag called `-level` that can be used to alter the logger pattern.The expected format is `MATCHING_STRING1:LOG_LEVEL1,MATCHING_STRING2:LOG_LEVEL2`
If matching string is *, it will change the log levels of all contained from all packages. Otherwise, the log level will be modified only on those loggers that will contain the matching string on any position. 
For example, having the parameter `process:DEBUG` will set the DEBUG level on all loggers that will contain the "process" string in their name ("process/sync", "process/interceptors", "process" and so on).
The rules are applied in the exact order they are provided, starting from left to the right part of the string

  Example: 
      `*:INFO,p2p:ERROR,*:DEBUG,data:INFO` will result in having the data package logger(s) on INFO log level and all other packages on DEBUG level

Defined logger levels are: `NONE, ERROR, WARN, INFO, DEBUG, TRACE`
TRACE will output anything,
NONE will practically silent everything. 
Whatever is in between will display the provided level + the left-most part from the afore mentioned list.

  Example: 
      `INFO` log level will output all logger lines with the levels `INFO` or `WARN` or `ERROR`.

The flag for storing into a file the received logger lines is  `-file`
  
  Example: 
          `./elrond-utils/logviewer -address localhost:8080 -level *:DEBUG,api:INFO -file` will start the binary that will try to connect to the locally-opened 8080 port, will set the log level
      to DEBUG for all packages except api package and will store all captured log lines in a file.

## FINAL THOUGHTS

	KEEP CALM AND VALIDATE ON ELROND NETWORK!
