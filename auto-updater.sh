#!/bin/bash
set -e

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


if [ -z "$LATEST" ]; then
                      echo "Couldn't get the latest tag from Github !!! " >> $HOME/autoupdate.status
                      echo " " >> $HOME/autoupdate.status
                        else 
              if [ "$CLONEDTAG" != "$LATEST" ]; then
                            echo "Latest tag on github: $LATEST" >> $HOME/autoupdate.status
                            echo "Triggering automated upgrade !" >> $HOME/autoupdate.status
                            echo " " >> $HOME/autoupdate.status
                            cd $HOME/elrond-go-scripts-v2/ && bash script.sh auto_upgrade
                              
                              else
                                echo "Nothing to do here... you are on the latest tag !" >> $HOME/autoupdate.status
                                echo " " >> $HOME/autoupdate.status
                              fi
    fi