#! /bin/bash

xrdb -merge ~/.Xresources 2> /dev/null
xrdb -merge ~/.Xmodmap 2> /dev/null
mykb x

picom -b 2> /dev/null
mkconf-i3status

xr p0
. ~/.post-xinitrc &> /dev/null
exec i3
