#!/bin/bash

# Description: Deletes all users and their home directories from the system.
#              User names are expected to be in the format 'userNN', where 'NN' is a number.
# Usage:       sudo ./delete_users.sh
# Version:     04/08/2014
# By:          Johan Nylander

if [ "$(whoami)" != "root" ] ; then
  echo -e "Usage: sudo `basename $0`"
  exit 1
else
  echo "Attempting to delete all users (userNN) on the current system"
  for d in /home/user* ; do
    u=$(basename "$d")
    echo "Deleting user $u"
    sudo userdel -r -f "$u"
  done
fi
