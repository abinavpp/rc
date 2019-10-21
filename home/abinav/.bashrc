#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

function is_in_colonvar() {
	declare -A fields
	local field
  local colonvar=$1 check=$2
  fields=`echo ${!colonvar} | awk -F: '{for (i = 1; i <= NF; i++) print $i}' | tr '\n' ' '`

	for field in ${fields[@]}; do
		if [[ $check == $field ]]; then
			unset fields
			return 0
		fi
	done
	unset fields
	return 1
}

function md_colonvar() {
  if [[ $# -lt 2 ]]; then
    return
  fi

  local colonvar=$1 opt=$2; shift 2
  local arg i

  # print the colonvar
  if [[ $opt == "-o" ]]; then
    echo ${!colonvar} | awk -F: '{for (i = 1; i <= NF; i++) print $i}'
    return
  fi

  # resets colonvar to it's $RESET_XXX var
  if [[ $opt == "-r" ]]; then
    local reset_colonvar="RESET_$colonvar"
    export $colonvar=${!reset_colonvar}
    return
  fi

  # edit colonvar in vim with newlines as "temporary separators". :wq to save
  # changes, :q to discard changes
  if [[ $opt == "-e" ]]; then
    local temp=$(mktemp -t md_colonvar.XXXXXX)
    echo ${!colonvar} | awk -F: '{for (i = 1; i <= NF; i++) print $i}' > $temp
    vim $temp
    export $colonvar=$(cat $temp | tr '\n' ':' | sed 's/:$//g')
    rm $temp
    return
  fi

  # prepend/append needs atleast one argument
  if [[ $# -lt 1 ]]; then
    return
  fi

  # if colonvar is blank or not set
  if [[ ! $(echo ${!colonvar}) =~ [[:print:]]+ ]]; then
    if ! is_in_colonvar $colonvar $1; then
      export $colonvar="$1"
    fi
    shift
    opt="-a" # XXX: Faking the option to force appending
  fi

  # prepend $@'s in reverse
  if [[ $opt == "-p" ]]; then
    for (( i=$#; i > 0; i-- )); do
      arg="${!i}"
      if ! is_in_colonvar $colonvar $arg; then
        export $colonvar="$arg:${!colonvar}"
      fi
    done
  fi

  # appends $@'s as it is.
  if [[ $opt == "-a" ]]; then
    for arg in "$@"; do
      if ! is_in_colonvar $colonvar $arg; then
        export $colonvar="${!colonvar}:$arg"
      fi
    done
  fi
}

function mdpath() {
  local opt=$1; shift;
  md_colonvar PATH $opt $(realpath "$@" 2> /dev/null);
}

function mdld() {
  local opt=$1; shift;
  md_colonvar LD_LIBRARY_PATH $opt $(realpath "$@" 2> /dev/null);
}

function mdlb() {
  local opt=$1; shift;
  md_colonvar LIBRARY_PATH $opt $(realpath "$@" 2> /dev/null);
}

export VISUAL="/usr/bin/vim -i NONE" # disables ~/.viminfo
export EDITOR="$VISUAL" # use $EDITOR if "our" vim creates trouble
export ABINAV="thats my name, that name again - is Mr.Plow"
export MANSECT="2:3:1:8:9:5:4:7:0:n:l"
export HISTSIZE=8192
export HISTFILESIZE=8192
export EXTRA_RUN="/home/abinav/rc/run"
export HOME_BIN="/home/abinav/bin"
export LLVM_DEV="/home/abinav/llvm_dev"

mdpath -p "$EXTRA_RUN" "$HOME_BIN"
md_colonvar PATH -p "."
export RESET_PATH=$PATH
export RESET_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
export RESET_LIBRARY_PATH=$LIBRARY_PATH

source /etc/bash.before &> /dev/null
source ${HOME}/bash.before &> /dev/null

sd=/usr/lib/systemd/system
cd=/var/lib/systemd/coredump

_psufield="flag,stat,euser,pid,ppid,pgid,sid,%mem,%cpu,\
wchan=WIDE-WCHAN-COLUMN,tty,cmd"
_pskfield="flag,stat,pid,ppid,pri,ni,class,bsdtime,cmd"
_tty=`tty`

nt_dir="/home/abinav/documents/notes/sys/"
voc_dir="/home/abinav/documents/notes/voc_db/"

t_col_path="/home/abinav/.t_col"

# Terminal colorscheme
t_bg_col_cur=
t_fg_col_cur=

function ind {
	$@ &
	disown $!
}

# updates the global script vars ${t_<fg/bg>_col_cur} as per the file name
# referred by ${t_col_path}
function _t_col_upd {
	local cur
	cur=`cat ${t_col_path} 2> /dev/null`
	if [[ ! $cur ]]; then
		cur="bl"
		echo $cur > "${t_col_path}"
	fi

	t_bg_col_cur="${t_bg_col[$cur]}"

	if [[ $cur == "wh" ]]; then
		t_fg_col_cur="${t_fg_col[bl]}"
	else
		t_fg_col_cur="${t_fg_col[wh]}"
	fi
}

#colors this pts
function cotty {
	[[ $# -ne 1 ]] && return
	echo $1 > ${t_col_path}
	_t_col_upd
	# tput clear
}

#colors all pts
function coall {
	[[ $# -ne 1 ]] && return

	[[ ! -e "${t_col_path}" ]] || touch "${t_col_path}"
	echo $1 > ${t_col_path}
	_t_col_upd # updates the global vars

	for t in /dev/pts/*
	do
		# skip this pts and ptmx, (the prompt will set color for this pts)
		if [[ $t == "${_tty}" || $t == "/dev/pts/ptmx" ]]; then
			continue
		fi

		echo -ne "${t_fg_col_cur}" > $t
		echo -ne "${t_bg_col_cur}" > $t
	done

	${EXTRA_RUN}/mkconf_gui $(echo $t_bg_col_cur | cut -c7-13)
	unset t
}


function prompt_command {
# \e] are xterm OSC \e[ are VT100 ctrl seq

# to set title
	echo -ne "\033]0; ${USER}@${HOSTNAME}[$_tty]    ${PWD}\007"

# VT100 sequences MUST be within \[ and \] in the PS1 string, same
# applies for xterm OSC or any non printable stuff in PS1 string.

# Using xterm OSC seems to create issues such as flickering, so I have
# only used it once at the last line of PS1.
	PS1='\[\e[38;5;76m\]\u' # VT100 ctrl seq works here
	PS1+='@\[\e[0m\]' # VT100 ctrl seq that reset all attributes
	PS1+='\h '
	PS1+='\W '
	PS1+='\$ ' # note that we NEED single quotes here!

	_t_col_upd
# this line forces the terminal colorscheme
	PS1+="\[${t_fg_col_cur}\]\[${t_bg_col_cur}\]"
}

_t_col_upd
${EXTRA_RUN}/mkconf_gui $(echo $t_bg_col_cur | cut -c7-13)

PROMPT_COMMAND=prompt_command

function in_array {
	local e match="$1"
	shift
	for e; do [[ "$e" == "$match" ]] && return 0; done
	return 1
}

function mkexec {
  file="$1"
  extension="${file##*.}"

	if [[ ! -e "$file" ]]; then
		touch "$file"

    if [[ $extension == "py" ]]; then
      true
    elif [[ $extension == "pl" ]]; then
      echo "#! /usr/bin/perl" > "$file" 
    else
      echo "#! /bin/bash" > "$file";
    fi
	fi
	chmod ugo+x $file;
}

function vim {
    local srv_name=$(tty)

    # we must hardcode /usr/bin/vim else we recurse!
    local cmd="/usr/bin/vim -i NONE -p --servername $srv_name"
    if [[ $1 == "-" ]]; then
        /usr/bin/vim -i NONE -
        return
    fi

    local bg_ps=$(ps -ef | /bin/grep -P "\s+$cmd")
    local bg_srv_name=/dev/$(echo $bg_ps | awk '{print $6}')
    local bg_pid=$(echo $bg_ps | awk '{print $2}')

    local args="" arg=""

    # if we have a non file arg and we have a bg_vim then run a new vim.
    for arg in "$@"; do
      if [[ ! -e $arg  && $bg_pid ]]; then
        /usr/bin/vim "$@"
        return
      fi
    done

    if [[ $bg_pid ]]; then # ie. bg_vim exists
      local bg_pwd=$(pwdx $bg_pid | awk '{print $2}')/
      # All arg should be file(s) here.
      for arg in "$@"; do
        arg=$(realpath "$arg")

        # if path is under bg_pwd, then access it relative (so that tab heading
        # won't look ugly)
        $cmd --remote-send "<esc>:tabnew ${arg##$bg_pwd} <CR>"
      done
      fg $(pid2jid $bg_pid)
      return

    else
      $cmd "$@"
    fi
}

function sgrep {
  local exclude=""
  if git status &> /dev/null; then
    exclude+="--exclude-dir=.git "
    if test -f tags && file tags | grep "Ctags tag file" &> /dev/null; then
      exclude+="--exclude=tags "
    fi

    if test -f cscope.out && file cscope.out | \
      grep "cscope reference data" &> /dev/null; then
      exclude+="--exclude=cscope.out --exclude=cscope.files "
    fi

    /bin/grep -P --color -n $exclude "$@"
  else
    /bin/grep -P --color -n "$@"
  fi
}

if am_i_home; then
    function make {
        local n_cores=$(nproc --all || getconf _NPROCESSORS_ONLN || echo 1)
        local cmd_make="/usr/bin/make -j $((n_cores + 1)) "

        local likelihood_linux_kernel=0 f
        local linux_kernel_top=("arch" "fs" "drivers" "kernel" "mm" \
            "tools" "Makefile")

        for f in *; do
            if in_array "$f" "${linux_kernel_top[@]}"; then
                ((likelihood_linux_kernel++))
            fi
        done

        if [[ $likelihood_linux_kernel -gt 5 ]]; then
            echo "Guessing $(pwd) as linux kernel source tree"
            if [[ -d cooked ]]; then
                echo "$cmd_make O=cooked $@"
                $cmd_make O=cooked $@
            else
                echo "mkdir cooked first, then try again"
                return 1
            fi
        else
            $cmd_make $@
        fi
    }
fi

function cd {
	if [[ "$PWD" =~ ^$LLVM_DEV/.*$ ]]; then
		local srcroot=$(srcerer 2> /dev/null)
		if [[ -z "$srcroot" ]]; then
			command cd "$@"
			return;
		fi

		local arg="$1"
		if [[ $arg == "" ]]; then
			command cd "$srcroot/"
		elif [[ $arg == "inc" ]]; then
			command cd "$srcroot/include/llvm"
		elif [[ $arg == "x86" ]]; then
			command cd "$srcroot/lib/Target/X86"
		elif [[ $arg == "cdg" ]]; then
			command cd "$srcroot/lib/CodeGen"
		elif [[ $arg == "tra" ]]; then
			command cd "$srcroot/lib/Transforms"
		elif [[ $arg == "tgt" ]]; then
			command cd "$srcroot/lib/Target"
		elif [[ $arg == "sca" ]]; then
			command cd "$srcroot/lib/Transforms/Scalar"
		else
			command cd "$@"
		fi
		return
	fi
		command cd "$@"
}

function pacdry {
	local pkg_infos=$(pacman -p --print-format "%n" "$@" | xargs pacman -Si)

	SAVEIFS=$IFS
	IFS=$'\n' # for filling arrays below

	local pkg_names=($(pacman -p --print-format "%n" "$@"))

	# can't use +ve look-behinds here since we need "var-length look-behind"!
	local pkg_download_szs=($(echo "$pkg_infos" | grep -P -o \
		'Download Size.*?[0-9\.]+.*' | grep -P -o '[0-9\.]+.*$' | \
		tr -d ' ')) # so you can pipe it to sort -h

	local pkg_installed_szs=($(echo "$pkg_infos" | grep -P -o \
		'Installed Size.*?[0-9\.]+.*$' | grep -P -o '[0-9\.]+.*$' | \
		tr -d ' '))

	IFS=$SAVEIFS

	for (( i=0; i<${#pkg_installed_szs[@]}; i++ )); do
		printf "%-30s%-20s%-20s\n" "${pkg_names[$i]}" "${pkg_download_szs[$i]}" \
			"${pkg_installed_szs[$i]}"
	done
}

function pacdry_fresh {
	local path_tmpdb=$(mktemp -t -d pacdry_tmpdb.XXXXXX)

	if [[ ! -e "$path_tmpdb" ]]; then
		echo 1>&2 "1 in a bajillion error: tmp file not creted"
		return 1
	fi

	sudo pacman -Sy --dbpath "$path_tmpdb" --logfile /dev/null 1>&2 && \
		pacdry --dbpath "$path_tmpdb" "$@"
	sudo rm -rf "$path_tmpdb" &> /dev/null
}

function pacdry2 {
	sudo pacman --logfile /dev/null "$@"
}

function pid2jid {
	jobs -l | gawk -v "_pid=$1" '$2 == _pid {print $1}' | \
		/bin/grep -oE "[[:digit:]]+"
}

function nt {
	if [[ -e "$nt_dir" ]]; then
		if [[ $# -ne 0  ]]; then
			vim "$nt_dir/$@"
		else
			ls "$nt_dir"
		fi
	else
		echo "$nt_dir not set"
	fi
}

_comp_nt() {
	local nt_comp=`ls $nt_dir | sed -r "/^\.+$/d"`
	local cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=( $(compgen -W "$nt_comp" -- $cur) )
}

# aliasing mn() unleashes hell when bashrc is sourced manually,
# so call it with mn, bash-completion done for it below
function mn {
	if [[ -e ~/.manvimrc ]]; then
		man "$@" | ${EDITOR} -u ~/.manvimrc -
	fi
}

function rn {
    local tempfile="$(mktemp -t tmp.XXXXXX)"
    ranger --choosedir="$tempfile" "${@:-$(pwd)}"
    test -f "$tempfile" &&
    if [[ "$(cat -- "$tempfile")" != "$(echo -n `pwd`)" ]]; then
        cd -- "$(cat "$tempfile")"
    fi
    rm -f -- "$tempfile"
}

function print_fortune {
	[[ "$PS1"  ]] && (type fortune &> /dev/null \
	&& echo -e "\e[00;36m$(fortune)\e[00m")
}

function print_batstat {
	[[ -e ${HOME}/.bat ]] && \
		(echo -ne "Capacity then : \e[0;31m"; cat ${HOME}/.bat)

	local batdir=/sys/class/power_supply/BAT*
	local batfull="${batdir}/*(energy_full|charge_full)"

	if [[ -n `dir ${batdir}` ]]; then
		if [[ -n `ls ${batfull}` ]]; then
			echo -ne "\e[00mCapacity now  : \e[0;32m"
			cat ${batfull}; echo -ne "\e[00m"
			cat ${batfull}  > ~/.bat
		fi
	fi
}

function print_voc {
	local vocpath n=1
	if [[ $# -eq 1 ]]; then
		n=$1
	fi
	vocpath="$EXTRA_RUN/voc"

	echo -e "\e[00;35m";
	[[ -e ${vocpath} ]] && ${vocpath} -r $n ${voc_dir}
	echo -e "\e[0m";
}

function vocdef {
	if [[ -e ${voc_dir}  && $# -eq 1 ]]; then
		grep -inr --color $1 ${voc_dir}/ 2> /dev/null
	fi
}

function vimj {
	local hst=$(cat /etc/hostname)

	# Apr 24 20:42:21 localhost sudo[5336]:
	journalctl --no-pager $* |
	grep -Pv  "^\w{3}\ \d{2}\ \d{2}:\d{2}:\d{2}\ $hst\ sudo\[\d+\].*$" | \
		${EDITOR} -c "set filetype=messages" - "+normal G"
}

function ntcry {
	local cry_dir="/home/abinav/documents/eph/_x/"
	local gpg="gpg --batch --yes"
	if [[ $# -ne 1 || ! -d $cry_dir ]]; then
		return
	fi

	local enc=$cry_dir/$1 dec="$cry_dir/_d_$1"
	local pass


	read -s -p "Speak friend and enter : " pass
	echo
	if [[ -e $enc ]]; then # doesn't decrypt non existent file
		$gpg --output $dec --passphrase $pass --decrypt $enc
		if [[ $? -ne 0 ]]; then
			return
		fi
	fi
	${EDITOR} $dec
	$gpg --output $enc --passphrase $pass --symmetric --cipher-algo AES256 $dec

	# clean up section
	rm $dec
	pkill gpg-agent
}

function cdp {
	if [[ $# -ne 1 ]]; then
		return
	fi
	local pid=`pgrep $1 | head -n1`
	if [[ $pid == "" ]]; then
		return
	fi
	echo "cmdline : "
	echo `tr -d '\0' < /proc/$pid/cmdline` # else null bytes throw warn
	cd /proc/$pid
}

function clhome {
	local f
	for f in "$@"; do
		[[ -n `ls ~/$f 2> /dev/null` ]] && rm ~/$f
	done
}

function 256col {
	echo -e "\e]10;#$1\007"
	ps -efl
	read
}

function cltex {
	local f
	for f in *.tex; do
		f=${f%.tex}
		rm ${f}.pdf ${f}.log ${f}.aux ${f}.pgf
	done
	rm missfont.log
}

function harakiri {
  echo "pkill -u ${USER} ?"
  read
  pkill -u ${USER}
}

if am_i_home; then
    function before_poweroff {
      mmrc -u xorg thumbnails chrome &> /dev/null
    }

    function poweroff { before_poweroff; /bin/poweroff; }

    function reboot { before_poweroff; /bin/reboot; }
fi

. /usr/share/bash-completion/completions/man
. /usr/share/bash-completion/completions/killall
. /usr/share/bash-completion/completions/pacman &> /dev/null
complete -F _man mn
complete -F _killall ka
complete -F _comp_nt nt
complete -F _pacman -o default pacdry
complete -F _pacman -o default pacdry2

bind '"\C-d":unix-filename-rubout'

clhome .sw? .calc_history .lesshst Desktop .texlive .elinks .rnd .viminfo

if ! pgrep Xorg 1> /dev/null && am_i_home; then
	mmrc xorg thumbnails &> /dev/null
	sudo mkconf_i3s &> /dev/null

	if [[ -n `type startx 2> /dev/null` ]]; then
		startx # we might want to see stderr here!
	fi
else

	print_fortune
	print_voc 1
	# print_batstat;
fi

if am_i_home; then
    source /usr/share/fzf/key-bindings.bash &> /dev/null
    source /usr/share/fzf/completion.bash &> /dev/null
else
    [[ -f ~/.fzf.bash ]] && source ~/.fzf.bash
fi

source /etc/bash.after &> /dev/null
source ${HOME}/bash.after &> /dev/null

alias grep='grep -P --color -n'
alias ka='killall'
alias srb='. ~/.bashrc'
alias ls='ls -a --color=auto --group-directories-first'
alias ll='ls -alih --color=auto --group-directories-first'
alias jobs='jobs -l'
alias lsblk='lsblk -o +FSTYPE,STATE,TRAN,PHY-SEC,LOG-SEC,MODEL,UUID'
alias cl='clear'
alias rm='rm -rfv'
alias cp='cp -vr'
alias tree='tree -aC'
alias kdbg='sudo cat /sys/kernel/debug/dynamic_debug/control'
alias kconf="zcat /proc/config.gz | vim -"
alias mkfs.ntfs='mkfs.ntfs -Q'
alias sudo='sudo '
alias perlpi='perl -lpe '
alias perl1='perl -ne '
alias readelf='readelf --wide'
alias prettyll='prettyll -simvar'

alias qtmux='tmux kill-server'
alias tmux='qtmux; tmux -u -2'

alias cmus='TERM=xterm-256color cmus'

alias vimb="vim ~/.bashrc"
alias vimv="vim ~/.vimrc"
alias vimm="vim -u /etc/vimrc"

alias psu="ps -o ${_psufield} --ppid 2 -p 2 -N"
alias psi="ps -o ${_psufield} --ppid=1"
alias psk="ps -o ${_pskfield} --ppid 2 -p 2"
alias pss='ps -o unit,cmd --ppid 2 -p 2 -N'
