#!/bin/bash
set -e

#Color to the people
RED='\x1B[0;31m'
CYAN='\x1B[0;36m'
GREEN='\x1B[0;32m'
NC='\x1B[0m'

#Handle some paths
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH

LATEST=$(curl --silent "https://api.github.com/repos/ElrondNetwork/elrond-go/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -d "$GOPATH/src/github.com/ElrondNetwork/elrond-go" ]; 
                  then 
                    cd $GOPATH/src/github.com/ElrondNetwork/elrond-go/
                    CLONEDTAG=$(git describe --exact-match --tags $(git log -n1 --pretty='%h'))
          else
            echo "--> elrond-go repo not found in path..." >> $HOME/autoupdate.status
    fi

echo `date` >> $HOME/autoupdate.status
echo "Your current tag is:  $CLONEDTAG" >> $HOME/autoupdate.status
echo "Latest tag on github: $LATEST" >> $HOME/autoupdate.status


if [ "$CLONEDTAG" != "$LATEST" ]; 
                          then
                            echo "Triggering automated upgrade !" >> $HOME/autoupdate.status
                            echo " " >> $HOME/autoupdate.status
                            cd $HOME/elrond-go-scripts-v2/ && bash script.sh auto_upgrade
                      else
                        echo "Nothing to do here... you are on the latest tag !" >> $HOME/autoupdate.status
                        echo " " >> $HOME/autoupdate.status
    fi
