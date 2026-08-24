#! /bin/bash

export QT_QPA_PLATFORMTHEME=qt6ct
# chrome ignores Xft.dpi and the Xcursor.size resource for cursors; without
# this it hardcodes 24px
export XCURSOR_SIZE=48

xrdb -merge ~/.Xresources 2> /dev/null
xrdb -merge ~/.Xmodmap 2> /dev/null

mykb x

picom -b 2> /dev/null
mkconf-i3status

xr p0
dbus-update-activation-environment --systemd DISPLAY XAUTHORITY
[ -r ~/.post-xinitrc ] && . ~/.post-xinitrc
exec i3
