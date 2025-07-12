#!/usr/bin/env sh
OPTS="-spaces"
rm -f final.tos

# Compile with various options
echo compile
rm *.o
vasmm68k_mot main.s -DSYNC=0 -DWIP=0 -DDEBUG=1 $OPTS -Felf -o final.o

# Link (gives better symbols)
echo link
vlink final.o -b ataritos -o final.tos

echo build done
