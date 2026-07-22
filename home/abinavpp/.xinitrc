#! /bin/bash

export QT_QPA_PLATFORMTHEME=qt6ct

xrdb -merge ~/.Xresources 2> /dev/null
xrdb -merge ~/.Xmodmap 2> /dev/null

mykb x

picom -b 2> /dev/null
mkconf-i3status

xr p0
dbus-update-activation-environment --systemd DISPLAY XAUTHORITY
[ -r ~/.post-xinitrc ] && . ~/.post-xinitrc
exec i3
