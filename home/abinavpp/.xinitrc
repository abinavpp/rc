#! /bin/bash

xrdb -merge ~/.Xresources 2> /dev/null
xrdb -merge ~/.Xmodmap 2> /dev/null
mykb x

picom -b 2> /dev/null
resdisp
mkconf-i3status
exec i3
