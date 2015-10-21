#!/bin/bash

# Description: Create N users with password PASSBASE+RANDNR
#              Prints a file 'user-info.txt' with user names and passwords
# Usage:       sudo ./create_users.sh Nusers
#              where 'Nusers' is a number
# Version:     10/21/2015
# By:          Johan Nylander

PASSBASE='catboxyellow'
USERINFO="user-info.txt"

if [ "$#" -eq 0 ] ; then
  echo -e "Usage: sudo `basename $0` Nusers"
  exit 1
else
  if [ -e "$USERINFO" ] ; then
    echo "File $USERINFO with password information already exist."
    echo "Will not overwrite. Quitting."
    exit 1
  else
    NUSERS=$1
    echo "Attempting to create $NUSERS on the current system"
    echo '' >> $USERINFO
    for u in $(seq -w 0 "$NUSERS"); do
      RANDNR=$(echo $RANDOM%900 | bc)
      PASSWD="${PASSBASE}${RANDNR}"
      USER="user${u}"
      echo "$USER"
      PASS=$(perl -e "print crypt($PASSWD, 'salt')")
      sudo useradd -m -p "$PASS" -s /bin/bash user${u}
      SRV=$(host -Tta $(hostname -s)|grep "has address"|awk '{print $1}')
      echo "User: $USER Passwd: $PASSWD SSH: ssh $USER@$SRV" >> $USERINFO
      echo '' >> $USERINFO
    done
    if [ -e "$USERINFO" ] ; then
        echo "Important: keep file $USERINFO with password information."
     fi
  fi
fi
