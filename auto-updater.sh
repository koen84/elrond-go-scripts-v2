#!/bin/bash
set -e

#Color to the people
RED='\x1B[0;31m'
CYAN='\x1B[0;36m'
GREEN='\x1B[0;32m'
NC='\x1B[0m'

source .identity
source functions.cfg

paths
LATEST=$(curl --silent "https://api.github.com/repos/ElrondNetwork/elrond-go/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -d "$GOPATH/src/github.com/ElrondNetwork/elrond-go" ]; 
                  then 
                    cd $GOPATH/src/github.com/ElrondNetwork/elrond-go/
                    CLONEDTAG=$(git describe --exact-match --tags $(git log -n1 --pretty='%h'))
          else
            echo -e
            echo -e "${RED}--> elrond-go repo not found in path...${NC}"
            echo -e
    fi

echo -e
echo "Your current tag is:  $CLONEDTAG"
echo "Latest tag on github: $LATEST"
echo -e


if [ "$CLONEDTAG" != "$LATEST" ]; 
                          then 
                            echo "Triggering automated upgrade !"
                      else
                        echo "Nothing to do here... you are on the latest tag !"
    fi