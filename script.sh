#!/bin/bash
set -e

#Color to the people
RED='\x1B[0;31m'
CYAN='\x1B[0;36m'
GREEN='\x1B[0;32m'
NC='\x1B[0m'

source configs/.identity
source configs/variables.cfg
source configs/functions.cfg


case "$1" in

'install')
  read -p "How many nodes do you want to run ? : " NUMBEROFNODES
  if [ $NUMBEROFNODES = "" ]
  then
      NUMBEROFNODES = 1
  fi
  
  prerequisites
  
  #Keep track of how many nodes you've started on the machine
  echo $NUMBEROFNODES | sudo tee -a /opt/node/.numberofnodes
  
  paths
  go_lang
  #If repos are present and you run install again this will clean up for you :D
  if [ -d "$GOPATH/src/github.com/ElrondNetwork/elrond-go" ]; then echo -e "${RED}--> Repos present. Please run update.sh script...${NC}"; echo -e; exit; fi
  mkdir -p $GOPATH/src/github.com/ElrondNetwork
  git_clone
  build_node
  build_keygen
  
  #Run the install process for each node
  for i in $(seq 1 $NUMBEROFNODES); 
        do 
         INDEX=$(( $i - 1 ))
         WORKDIR="/opt/node/node-$INDEX"
         
         install
         node_name
         keys
         systemd
       done

  echo -e 
  read -p "Do you want to install the auto-update function (Default No) ? (Yy/Nn)" yn
  echo -e
  case $yn in
       [Yy]* )
          echo -e "${GREEN}Adding auto-update to crontab !${NC}"
          autoupdate  
            ;;
       [Nn]* )
          echo -e "${GREEN}Fine... let's continue...${NC}"
            ;;
           * )
           echo -e "${GREEN}I'll take that as a no then...${NC}"
            ;;
      esac

  ;;

'install_hosts')
  deploy_to_host
  for HOST in $(cat target_ips) 
    do
      echo -e
      echo -e "${GREEN}--------------------------------------------------------------------------------${NC}"
      echo -e 
      echo -e "${GREEN}---> Running the install process on the ${CYAN}$HOST${GREEN} machine ...${NC}"
      echo -e
      echo -e "${GREEN}--------------------------------------------------------------------------------${NC}"
      echo -e
    ssh -t -o StrictHostKeyChecking=no -p $SSHPORT -i "$PEM" $CUSTOM_USER@$HOST "cd $CUSTOM_HOME/$DIRECTORY_NAME && ./script.sh install"
    done 
  ;;

'upgrade')
  paths
  #Remove previously cloned repos  
  if [ -d "$GOPATH/src/github.com/ElrondNetwork/elrond-go" ]; then sudo rm -rf $GOPATH/src/github.com/ElrondNetwork/elrond-*; echo -e; echo -e "${RED}--> Repos present. Removing and fetching again...${NC}"; echo -e; fi
  #Backup prefs.toml which has node name
  git_clone
  build_node
  
  INSTALLEDNODES=$(cat /opt/node/.numberofnodes)
  
  #Run the update process for each node
  for i in $(seq 1 $INSTALLEDNODES);
      do
        UPDATEINDEX=$(( $i - 1 ))
        UPDATEWORKDIR="/opt/node/node-$UPDATEINDEX"
        sudo cp $UPDATEWORKDIR/config/prefs.toml $UPDATEWORKDIR/config/prefs.toml.save
  
        read -p "Do you want to remove the current Node DB & Logs for node-$UPDATEINDEX ? (yes/no): " CLEAN
        if [ "$CLEAN" != "no" ]
                  then
                    sudo systemctl stop elrond-node-$UPDATEINDEX
                    cleanup
                    update
                    sudo mv $UPDATEWORKDIR/config/prefs.toml.save $UPDATEWORKDIR/config/prefs.toml && sudo chown node:node $UPDATEWORKDIR/config/prefs.toml
                    sudo systemctl start elrond-node-$UPDATEINDEX
                  else
                    sudo systemctl stop elrond-node-$UPDATEINDEX
                    update
                    sudo mv $UPDATEWORKDIR/config/prefs.toml.save $UPDATEWORKDIR/config/prefs.toml && sudo chown node:node $UPDATEWORKDIR/config/prefs.toml
                    sudo systemctl start elrond-node-$UPDATEINDEX
            fi
      done
  ;;

'auto_upgrade')
  paths
  #Remove previously cloned repos  
  if [ -d "$GOPATH/src/github.com/ElrondNetwork/elrond-go" ]; then sudo rm -rf $GOPATH/src/github.com/ElrondNetwork/elrond-*; fi
  git_clone
  build_node
  
  INSTALLEDNODES=$(cat /opt/node/.numberofnodes)
  
  #Run the update process for each node
  for i in $(seq 1 $INSTALLEDNODES);
      do
        UPDATEINDEX=$(( $i - 1 ))
        UPDATEWORKDIR="/opt/node/node-$UPDATEINDEX"
        sudo cp $UPDATEWORKDIR/config/prefs.toml $UPDATEWORKDIR/config/prefs.toml.save
        sudo systemctl stop elrond-node-$UPDATEINDEX
        update
        sudo mv $UPDATEWORKDIR/config/prefs.toml.save $UPDATEWORKDIR/config/prefs.toml && sudo chown node:node $UPDATEWORKDIR/config/prefs.toml
        sudo systemctl start elrond-node-$UPDATEINDEX
      done
  ;;

'upgrade_hosts')
  deploy_to_host
  for HOST in $(cat target_ips) 
    do
      echo -e
      echo -e "${GREEN}--------------------------------------------------------------------------------${NC}"
      echo -e 
      echo -e "${GREEN}---> Running the upgrade process on the ${CYAN}$HOST${GREEN} machine ...${NC}"
      echo -e
      echo -e "${GREEN}--------------------------------------------------------------------------------${NC}"
      echo -e
      ssh -t -o StrictHostKeyChecking=no -p $SSHPORT -i "$PEM" $CUSTOM_USER@$HOST "cd $CUSTOM_HOME/$DIRECTORY_NAME && ./script.sh upgrade"
    done 
  ;;

'start')
  NODESTOSTART=$(cat /opt/node/.numberofnodes)
  for i in $(seq 1 $NODESTOSTART);
      do
        STARTINDEX=$(( $i - 1 ))
        echo -e
        echo -e "${GREEN}Starting Elrond Node-$STARTINDEX binary on host ${CYAN}$HOST${GREEN}...${NC}"
        echo -e
        sudo systemctl start elrond-node-$STARTINDEX && sudo systemctl status elrond-node-$STARTINDEX
      done
  ;;

'start_hosts')
  
  for HOST in $(cat target_ips) 
    do
    echo -e
    echo -e "${GREEN}Starting Elrond Node binaries on host ${CYAN}$HOST${GREEN}...${NC}"
    echo -e
    ssh -t -o StrictHostKeyChecking=no -p $SSHPORT -i "$PEM" $CUSTOM_USER@$HOST "cd $CUSTOM_HOME/$DIRECTORY_NAME && ./script.sh start"
    done 
  ;;

'stop')
  NODESTOSTOP=$(cat /opt/node/.numberofnodes)
  for i in $(seq 1 $NODESTOSTOP);
      do
        STOPINDEX=$(( $i - 1 ))
        echo -e
        echo -e "${GREEN}Stopping Elrond Node-$STOPINDEX binary on host ${CYAN}$HOST${GREEN}...${NC}"
        echo -e
        sudo systemctl start elrond-node-$STOPINDEX
      done
  ;;

'stop_hosts')
  
  for HOST in $(cat target_ips) 
    do
    echo -e
    echo -e "${GREEN}Stopping Elrond Node binaries on host ${CYAN}$HOST${GREEN}...${NC}"
    echo -e
    ssh -t -o StrictHostKeyChecking=no -p $SSHPORT -i "$PEM" $CUSTOM_USER@$HOST "cd $CUSTOM_HOME/$DIRECTORY_NAME && ./script.sh stop"
    done 
  ;;

'deploy')
  deploy_to_host
  ;;

*)
  echo "Usage: Missing parameter ! [install|install_hosts|upgrade|upgrade_hosts|start|start_hosts|stop|stop_hosts]"
  ;;
esac