#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

_psufield="flag,stat,euser,pid,ppid,pgid,sid,%mem,%cpu,\
wchan=WIDE-WCHAN-COLUMN,tty,cmd"
_pskfield="flag,stat,pid,ppid,pri,ni,class,bsdtime,cmd"

function ind {
	$@ &
	disown $!
}

alias ka='killall'
alias grep='grep -P --color -n'
alias srb='. ~/.bashrc'
alias ls='ls -a --color=auto --group-directories-first'
alias ll='ls -alih --color=auto --group-directories-first'
alias jobs='jobs -l'
alias lsblk='lsblk -o +FSTYPE,STATE,TRAN,PHY-SEC,LOG-SEC,MODEL,UUID'
alias fswp='sudo find / -regextype posix-egrep -regex ".*/\.s[[:alpha:]]{2}$"'
alias cl='clear'
alias rm='rm -rfv'
alias cp='cp -vr'
alias tree='tree -aC'
alias rs='rsync -ah --progress --stats'
alias kdbg='sudo cat /sys/kernel/debug/dynamic_debug/control'
alias kconf="zcat /proc/config.gz | ${EDITOR} -"
alias mkfs.ntfs='mkfs.ntfs -Q'
alias sudo='sudo '
alias perlpi='perl -lpe '
alias perl1='perl -ne '

alias vimb="${EDITOR} ~/.bashrc"
alias vimv="${EDITOR} ~/.vimrc"
alias vimm="${EDITOR} -u /etc/vimrc"

alias psu="ps -o ${_psufield} --ppid 2 -p 2 -N"
alias psi="ps -o ${_psufield} --ppid=1"
alias psk="ps -o ${_pskfield} --ppid 2 -p 2"
alias pss='ps -o unit,cmd --ppid 2 -p 2 -N'

function mkexec { touch $1; chmod ugo+x $1; }
