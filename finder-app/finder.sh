#!/bin/sh

if [ $# -ne 2 ]
  then
    echo "Need 2 args"
    exit 1
  else
    FILESDIR=$1
    SEARCHSTR=$2
   if [ -d "$FILESDIR" ]; 
     then
     echo "$FILESDIR is a directory"
   else
     echo "$FILESDIR is not a directory"
    exit 1
   fi
    
fi

Y=`grep -r $SEARCHSTR $FILESDIR | wc -l`
X=`find $FILESDIR -type f | wc -l`

echo "The number of files are $X and the number of matching lines are $Y"
