#!/bin/bash
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
DINIT_VER=$(/lib/dinit/dinit --version | grep version)

if test -e /etc/antix-version; then
 OS=antiX
else
  OS=init-diversity
fi

echo ""
echo "${BOLD}Welcome to $OS Linux!${NORMAL}"
echo "${BOLD}$DINIT_VER${NORMAL} is now booting up ${BOLD}$OS_VER${NORMAL}"
echo ""
