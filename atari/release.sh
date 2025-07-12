#!/usr/bin/env sh
OPTS="-spaces"
rm -f final.tos

# Compile with various options
echo compile
rm *.o
vasmm68k_mot main.s -DSYNC=0 -DWIP=0 -DDEBUG=0 $OPTS -Ftos -o tmp/CURLY.TOS
upx tmp/CURLY.TOS
cd tmp
zip ../CURLY.ZIP *
cd ..