#!/bin/bash
set -e

#Color to the people
RED='\x1B[0;31m'
CYAN='\x1B[0;36m'
GREEN='\x1B[0;32m'
NC='\x1B[0m'

source .identity
source variables.cfg
source functions.cfg


case "$1" in

'install')
  prerequisites
  paths
  go_lang
  #If repos are present and you run install again this will clean up for you :D
  if [ -d "$GOPATH/src/github.com/ElrondNetwork/elrond-go" ]; then echo -e "${RED}--> Repos present. Please run update.sh script...${NC}"; echo -e; exit; fi
  mkdir -p $GOPATH/src/github.com/ElrondNetwork
  git_clone
  build_node
  install
  node_name
  keys
  systemd
  ;;

'install_hosts')
  deploy_to_host
  for HOST in $(cat target_ips) 
    do
    ssh -t -o StrictHostKeyChecking=no -i "$PEM" $REMOTE_USER@$HOST "cd $REMOTE_HOME/$DIRECTORY_NAME && ./script.sh install"
    done 
  ;;

'upgrade')
  paths
  #Remove previously cloned repos  
  if [ -d "$GOPATH/src/github.com/ElrondNetwork/elrond-go" ]; then sudo rm -rf $GOPATH/src/github.com/ElrondNetwork/elrond-*; echo -e; echo -e "${RED}--> Repos present. Removing and fetching again...${NC}"; echo -e; fi
  #Backup prefs.toml which has node name
  sudo cp /opt/node/config/prefs.toml /opt/node/config/prefs.toml.save
  git_clone
  build_node
  read -p "Do you want to remove the current Node DB & Logs ? (yes/no): " CLEAN
  if [ "$CLEAN" != "no" ]
                then
                  sudo systemctl stop elrond-node
                  cleanup
                  update
                  sudo mv /opt/node/config/prefs.toml.save /opt/node/config/prefs.toml && sudo chown node:node /opt/node/config/prefs.toml
                  sudo systemctl start elrond-node
          else
            sudo systemctl stop elrond-node
            update
            sudo mv /opt/node/config/prefs.toml.save /opt/node/config/prefs.toml && sudo chown node:node /opt/node/config/prefs.toml
            sudo systemctl start elrond-node
  fi
  ;;

'upgrade_hosts')
  deploy_to_host
  for HOST in $(cat target_ips) 
    do
    ssh -t -o StrictHostKeyChecking=no -i "$PEM" $REMOTE_USER@$HOST "cd $REMOTE_HOME/$DIRECTORY_NAME && ./script.sh upgrade"
    done 
  ;;

'start_hosts')
  
  for HOST in $(cat target_ips) 
    do
    echo -e
    echo -e "${GREEN}Starting Elrond Node bunary on host ${CYAN}$HOST${GREEN}...${NC}"
    echo -e
    ssh -t -o StrictHostKeyChecking=no -i "$PEM" $REMOTE_USER@$HOST "sudo systemctl start elrond-node.service && sudo systemctl status elrond-node.service"
    done 
  ;;

*)
  echo "Usage: Missing parameter ! [install|install_hosts|upgrade|upgrade_hosts|start_hosts]"
  ;;
esac