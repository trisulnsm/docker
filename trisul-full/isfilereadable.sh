#!/bin/bash
file=$1
user=$(id)
if ! [[ -r "$file" ]] ; then
    echo "CHECKREADABLE:  '$file' is NOT  readable by user $user"
    exit 1
else
    echo "CHECKREADABLE:  '$file' is readable by user $user"
    exit 0 
fi
