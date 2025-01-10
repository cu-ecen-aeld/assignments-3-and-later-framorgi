#!/bin/sh

if [ $# -ne 2 ]
  then
    echo "Need 2 args"
    exit 1
    
fi
WRITEFILE=$1
WRITESTR=$2
DIR=`dirname $1`
echo $DIR 
mkdir -p $DIR 

echo $WRITESTR > $WRITEFILE || { echo "Errore: impossibile scrivere su $WRITEFILE"; exit 1; }
