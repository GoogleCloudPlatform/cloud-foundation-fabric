#!/bin/bash
# https://stackoverflow.com/questions/50413579/bash-convert-netmask-in-cidr-notation
c=0 x=0$(printf '%o' $${1//./ })
while [ $x -gt 0 ]; do
  let c+=$((x % 2)) 'x>>=1'
done
echo $c
