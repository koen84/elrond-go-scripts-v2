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
  #Check if CUSTOM_HOME exists
  if ! [ -d "$CUSTOM_HOME" ]; then echo -e "${RED}Please configure your variables first ! (variables.cfg --> CUSTOM_HOME & CUSTOM_USER)${NC}"; exit; fi
  
  #Keep track of how many nodes you've started on the machine
  echo "$NUMBEROFNODES" > $CUSTOM_HOME/.numberofnodes
  paths
  go_lang
  #If repos are present and you run install again this will clean up for you :D
  if [ -d "$GOPATH/src/github.com/ElrondNetwork/elrond-go" ]; then echo -e "${RED}--> Repos present. Either run the upgrade command or cleanup & install again...${NC}"; echo -e; exit; fi
  mkdir -p $GOPATH/src/github.com/ElrondNetwork
  git_clone
  build_node
  build_keygen
  
  #Run the install process for each node
  for i in $(seq 1 $NUMBEROFNODES); 
        do 
         INDEX=$(( $i - 1 ))
         WORKDIR="$CUSTOM_HOME/elrond-nodes/node-$INDEX"
         install
         node_name
         keys
         systemd
         install_sudofix
       done

  echo -e
  echo -e "${GREEN}--------------------------------------------------------------------------------${NC}"
  echo -e "${GREEN}---> This next section asks if you want to install the ${CYAN}AUTOPUDATER${GREEN}${NC}"
  echo -e "${GREEN}--------------------------------------------------------------------------------${NC}"

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
  sudo chown -R $CUSTOM_USER:$CUSTOM_USER $CUSTOM_HOME/elrond-nodes
  ;;

'install-remote')
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
  git_clone
  build_node
  
  INSTALLEDNODES=$(cat $CUSTOM_HOME/.numberofnodes)
  
  #Run the update process for each node
  for i in $(seq 1 $INSTALLEDNODES);
      do
        UPDATEINDEX=$(( $i - 1 ))
        UPDATEWORKDIR="$CUSTOM_HOME/elrond-nodes/node-$UPDATEINDEX"
        cp $UPDATEWORKDIR/config/prefs.toml $UPDATEWORKDIR/config/prefs.toml.save
        
        read -p "Do you want to remove the current Node DB & Logs for node-$UPDATEINDEX ? (yes/no):" CLEAN
        if [ "$CLEAN" != "no" ]
                  then
                    sudo systemctl stop elrond-node-$UPDATEINDEX
                    cleanup
                    update
                    mv $UPDATEWORKDIR/config/prefs.toml.save $UPDATEWORKDIR/config/prefs.toml
                    sudo systemctl start elrond-node-$UPDATEINDEX
                  else
                    sudo systemctl stop elrond-node-$UPDATEINDEX
                    update
                    mv $UPDATEWORKDIR/config/prefs.toml.save $UPDATEWORKDIR/config/prefs.toml
                    sudo systemctl start elrond-node-$UPDATEINDEX
            fi
      done
  ;;

'auto_upgrade')
  paths
  #Remove previously cloned repos
  if [ -d "$GOPATH/src/github.com/ElrondNetwork/elrond-go" ]; then rm -rf $GOPATH/src/github.com/ElrondNetwork/elrond-*; fi
  git_clone
  build_node
  
  INSTALLEDNODES=$(cat $CUSTOM_HOME/.numberofnodes)  
  curl --silent "https://api.github.com/repos/ElrondNetwork/elrond-go/releases/latest" | grep "body" > $HOME/tmp
  
  if grep -q "*This release should start with a new DB*" "$HOME/tmp" 
                                        then DBQUERY=1
                            else DBQUERY=0 
                  fi

if [ "$DBQUERY" -eq "1" ]; then

                  for i in $(seq 1 $INSTALLEDNODES);
                      do
                        UPDATEINDEX=$(( $i - 1 ))
                        UPDATEWORKDIR="$CUSTOM_HOME/elrond-nodes/node-$UPDATEINDEX"
                        cp $UPDATEWORKDIR/config/prefs.toml $UPDATEWORKDIR/config/prefs.toml.save
                        sudo systemctl stop elrond-node-$UPDATEINDEX
                        echo "Database Cleanup Called ! Erasing DB for elrond-node-$UPDATEINDEX..." >> $HOME/autoupdate.status
                        cleanup
                        update
                        mv $UPDATEWORKDIR/config/prefs.toml.save $UPDATEWORKDIR/config/prefs.toml
                        sudo systemctl start elrond-node-$UPDATEINDEX       
                      done
      
    else
      for i in $(seq 1 $INSTALLEDNODES);
          do
            UPDATEINDEX=$(( $i - 1 ))
            UPDATEWORKDIR="$CUSTOM_HOME/elrond-nodes/node-$UPDATEINDEX"
            cp $UPDATEWORKDIR/config/prefs.toml $UPDATEWORKDIR/config/prefs.toml.save
            sudo systemctl stop elrond-node-$UPDATEINDEX
            echo "Database Cleanup Not Needed for elrond-node-$UPDATEINDEX ! Moving to next step... " >> $HOME/autoupdate.status
            update
            mv $UPDATEWORKDIR/config/prefs.toml.save $UPDATEWORKDIR/config/prefs.toml
            sudo systemctl start elrond-node-$UPDATEINDEX
          done
    fi

    rm $HOME/tmp    
  ;;

'upgrade-remote')
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
  NODESTOSTART=$(cat $CUSTOM_HOME/.numberofnodes)
  for i in $(seq 1 $NODESTOSTART);
      do
        STARTINDEX=$(( $i - 1 ))
        echo -e
        echo -e "${GREEN}Starting Elrond Node-$STARTINDEX binary on host ${CYAN}$HOST${GREEN}...${NC}"
        echo -e
        sudo systemctl start elrond-node-$STARTINDEX
      done
  ;;

'start-remote')
  for HOST in $(cat config/target_ips) 
    do
    echo -e
    echo -e "${GREEN}Starting Elrond Node binaries on host ${CYAN}$HOST${GREEN}...${NC}"
    echo -e
    ssh -t -o StrictHostKeyChecking=no -p $SSHPORT -i "$PEM" $CUSTOM_USER@$HOST "cd $CUSTOM_HOME/$DIRECTORY_NAME && ./script.sh start"
    done 
  ;;

'stop')
  NODESTOSTOP=$(cat $CUSTOM_HOME/.numberofnodes)
  for i in $(seq 1 $NODESTOSTOP);
      do
        STOPINDEX=$(( $i - 1 ))
        echo -e
        echo -e "${GREEN}Stopping Elrond Node-$STOPINDEX binary on host ${CYAN}$HOST${GREEN}...${NC}"
        echo -e
        sudo systemctl stop elrond-node-$STOPINDEX
      done
  ;;

'stop-remote')
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
          
          if [[ -f $CUSTOM_HOME/.numberofnodes ]]; then
            NODESTODESTROY=$(cat $CUSTOM_HOME/.numberofnodes)
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
                          if [ -d $CUSTOM_HOME/elrond-nodes/node-$KILLINDEX ]; then sudo rm -rf $CUSTOM_HOME/elrond-nodes/node-$KILLINDEX; fi
                    done
          fi
            
            #Reload systemd after deleting node units
            sudo systemctl daemon-reload
            echo -e
            echo -e "${GREEN}Removing auto-updater crontab from host ${CYAN}$HOST${GREEN}...${NC}"
            echo -e      
            crontab -l | grep -v 'elrond-go-scripts-v2/auto-updater.sh'  | crontab -
            
            echo -e "${GREEN}Removing cloned elrond-go & elrond-configs repo from host ${CYAN}$HOST${GREEN}...${NC}"
            echo -e      
            if [ -d "$GOPATH/src/github.com/ElrondNetwork/elrond-go" ]; then sudo rm -rf $GOPATH/src/github.com/ElrondNetwork/elrond-*; fi      
            
            # remove the sudofix file
            sudo rm -f $sudofix
            ;;
            
       [Nn]* )
          echo -e "${GREEN}Fine ! Skipping cleanup on this machine...${NC}"
            ;;
            
           * )
           echo -e "${GREEN}I'll take that as a no then... moving on...${NC}"
            ;;
      esac
  ;;

'cleanup-remote')
  
  for HOST in $(cat config/target_ips) 
    do
    echo -e
    echo -e "${GREEN}Running cleanup script on host ${CYAN}$HOST${GREEN}...${NC}"
    echo -e
    ssh -t -o StrictHostKeyChecking=no -p $SSHPORT -i "$PEM" $CUSTOM_USER@$HOST "cd $CUSTOM_HOME/$DIRECTORY_NAME && ./script.sh cleanup"
    done 
  ;;

'crontab')
  echo -e
  echo -e "${GREEN}--------------------------------------------------------------------------------${NC}"
  echo -e "${GREEN}---> This next section asks if you want to install the ${CYAN}AUTOPUDATER${GREEN}${NC}"
  echo -e "${GREEN}--------------------------------------------------------------------------------${NC}"

  echo -e 
  read -p "Do you want to install the auto-update function (Default No) ? (Yy/Nn)" yn
  echo -e
  case $yn in
       [Yy]* )
          echo -e "${GREEN}Adding auto-update to crontab !${NC}"
          if (crontab -l 2>/dev/null | grep -q "auto-updater.sh"); then echo "Crontab already installed"; else autoupdate; fi  
            ;;
       [Nn]* )
          echo -e "${GREEN}Fine... let's continue...${NC}"
            ;;
           * )
           echo -e "${GREEN}I'll take that as a no then...${NC}"
            ;;
      esac
  ;;

'crontab-remote')
  
  for HOST in $(cat config/target_ips) 
    do
    echo -e
    echo -e "${GREEN}Running auto-update cronjob install script on host ${CYAN}$HOST${GREEN}...${NC}"
    echo -e
    ssh -t -o StrictHostKeyChecking=no -p $SSHPORT -i "$PEM" $CUSTOM_USER@$HOST "cd $CUSTOM_HOME/$DIRECTORY_NAME && ./script.sh crontab"
    done 
  ;;




'deploy')
  deploy_to_host
  ;;
  
'sudofix')
        INSTALLEDNODES=$(cat $CUSTOM_HOME/.numberofnodes)
        for i in $(seq 1 $INSTALLEDNODES);
                do
                        INDEX=$(( $i - 1 ))
                        install_sudofix
                done
        ;;
        
*)
  echo "Usage: Missing parameter ! [install|install-remote|upgrade|upgrade-remote|start|start-remote|stop|stop-remote|cleanup|cleanup-remote]"
  ;;
esac
