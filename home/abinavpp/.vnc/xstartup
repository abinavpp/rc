#! /bin/bash

xrdb -merge ~/.Xresources 2> /dev/null
xrdb -merge ~/.Xmodmap 2> /dev/null

picom -b --experimental-backends
mkconf-i3status
exec i3
