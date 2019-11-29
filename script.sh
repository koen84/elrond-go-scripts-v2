#!/bin/bash
set -e

#Color to the people
RED='\x1B[0;31m'
CYAN='\x1B[0;36m'
GREEN='\x1B[0;32m'
NC='\x1B[0m'

source config/identity
source config/variables.cfg
source config/functions.cfg


case "$1" in

'install')
  read -p "How many nodes do you want to run ? : " NUMBEROFNODES
  if [ $NUMBEROFNODES = "" ]
  then
      NUMBEROFNODES = 1
  fi
  
  prerequisites
  replicant
  
  #Keep track of how many nodes you've started on the machine
  echo $NUMBEROFNODES | sudo tee /opt/node/.numberofnodes
  
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
  for HOST in $(cat config/target_ips) 
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
  curl --silent "https://api.github.com/repos/ElrondNetwork/elrond-go/releases/latest" | grep "body" > $HOME/tmp
  
  if grep -q "*This release should start with a new DB*" "$HOME/tmp" 
                                        then DBQUERY=1
                            else DBQUERY=0 
                  fi

if [ "$DBQUERY" -eq "1" ]; then

  for i in $(seq 1 $INSTALLEDNODES);
      do
        UPDATEINDEX=$(( $i - 1 ))
        UPDATEWORKDIR="/opt/node/node-$UPDATEINDEX"
        sudo cp $UPDATEWORKDIR/config/prefs.toml $UPDATEWORKDIR/config/prefs.toml.save
        sudo systemctl stop elrond-node-$UPDATEINDEX
        echo "Database Cleanup Called ! Erasing DB for elrond-node-$UPDATEINDEX..." >> $HOME/autoupdate.status
        cleanup
        update
        sudo mv $UPDATEWORKDIR/config/prefs.toml.save $UPDATEWORKDIR/config/prefs.toml && sudo chown node:node $UPDATEWORKDIR/config/prefs.toml
        sudo systemctl start elrond-node-$UPDATEINDEX       
      done
      
    else
      for i in $(seq 1 $INSTALLEDNODES);
          do
            UPDATEINDEX=$(( $i - 1 ))
            UPDATEWORKDIR="/opt/node/node-$UPDATEINDEX"
            sudo cp $UPDATEWORKDIR/config/prefs.toml $UPDATEWORKDIR/config/prefs.toml.save
            sudo systemctl stop elrond-node-$UPDATEINDEX
            echo "Database Cleanup Not Needed for elrond-node-$UPDATEINDEX ! Moving to next step... " >> $HOME/autoupdate.status
            update
            sudo mv $UPDATEWORKDIR/config/prefs.toml.save $UPDATEWORKDIR/config/prefs.toml && sudo chown node:node $UPDATEWORKDIR/config/prefs.toml
            sudo systemctl start elrond-node-$UPDATEINDEX
          done
    fi
  ;;

'upgrade_hosts')
  deploy_to_host
  for HOST in $(cat config/target_ips) 
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
  
  for HOST in $(cat config/target_ips) 
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
        sudo systemctl stop elrond-node-$STOPINDEX
      done
  ;;

'stop_hosts')
  
  for HOST in $(cat config/target_ips) 
    do
    echo -e
    echo -e "${GREEN}Stopping Elrond Node binaries on host ${CYAN}$HOST${GREEN}...${NC}"
    echo -e
    ssh -t -o StrictHostKeyChecking=no -p $SSHPORT -i "$PEM" $CUSTOM_USER@$HOST "cd $CUSTOM_HOME/$DIRECTORY_NAME && ./script.sh stop"
    done 
  ;;

'cleanup')
  paths
  echo -e 
  read -p "Do you want to delete installed nodes (Default No) ? (Yy/Nn)" yn
  echo -e
  case $yn in
       [Yy]* )
          echo -e "${RED}OK ! Cleaning everything !${NC}"
          
          NODESTODESTROY=$(cat /opt/node/.numberofnodes)
              for i in $(seq 1 $NODESTODESTROY);
                  do
                      KILLINDEX=$(( $i - 1 ))
                        echo -e
                        echo -e "${GREEN}Stopping Elrond Node-$KILLINDEX binary on host ${CYAN}$HOST${GREEN}...${NC}"
                        echo -e
                        [ -e /etc/systemd/system/elrond-node-$KILLINDEX.service ] && sudo systemctl stop elrond-node-$KILLINDEX
                        echo -e "${GREEN}Erasing unit file and node folder for Elrond Node-$KILLINDEX...${NC}"
                        echo -e
                        [ -e /etc/systemd/system/elrond-node-$KILLINDEX.service ] && sudo rm /etc/systemd/system/elrond-node-$KILLINDEX.service
                        if [ -d /opt/node/node-$KILLINDEX ]; then sudo rm -rf /opt/node/node-$KILLINDEX; fi
                        
                  done
            
            #Reload systemd after deleting node units
            sudo systemctl daemon-reload
            echo -e
            echo -e "${GREEN}Removing auto-updater crontab from host ${CYAN}$HOST${GREEN}...${NC}"
            echo -e      
            crontab -l | grep -v 'elrond-go-scripts-v2/auto-updater.sh'  | crontab -
            
            echo -e "${GREEN}Removing cloned elrond-go & elrond-configs repo from host ${CYAN}$HOST${GREEN}...${NC}"
            echo -e      
            if [ -d "$GOPATH/src/github.com/ElrondNetwork/elrond-go" ]; then sudo rm -rf $GOPATH/src/github.com/ElrondNetwork/elrond-*; fi      
            ;;
            
       [Nn]* )
          echo -e "${GREEN}Fine ! Skipping cleanup on this machine...${NC}"
            ;;
            
           * )
           echo -e "${GREEN}I'll take that as a no then... moving on...${NC}"
            ;;
      esac
  ;;

'cleanup_hosts')
  
  for HOST in $(cat config/target_ips) 
    do
    echo -e
    echo -e "${GREEN}Running cleanup script on host ${CYAN}$HOST${GREEN}...${NC}"
    echo -e
    ssh -t -o StrictHostKeyChecking=no -p $SSHPORT -i "$PEM" $CUSTOM_USER@$HOST "cd $CUSTOM_HOME/$DIRECTORY_NAME && ./script.sh cleanup"
    done 
  ;;

'deploy')
  deploy_to_host
  ;;

*)
  echo "Usage: Missing parameter ! [install|install_hosts|upgrade|upgrade_hosts|start|start_hosts|stop|stop_hosts|cleanup|cleanup_hosts]"
  ;;
esac