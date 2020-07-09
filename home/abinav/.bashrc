source /etc/.pre-bashrc &> /dev/null
source ${HOME}/.pre-bashrc &> /dev/null

function is_in_delimvar() {
  declare -A fields
  local field
  local delim=$1 delimvar=$2 check=$3
  fields=`echo ${!delimvar} | awk -F$delim '{for (i = 1; i <= NF; i++) print $i}' | tr '\n' ' '`

  for field in ${fields[@]}; do
    if [[ $check == $field ]]; then
      unset fields
      return 0
    fi
  done
  unset fields
  return 1
}

function edelimvar() {
  if [[ $# -lt 3 ]]; then
    return
  fi

  local delim=$1 delimvar=$2 opt=$3; shift 3
  local arg i

  # print the delimvar
  if [[ $opt == "-o" ]]; then
    echo ${!delimvar} | awk -F$delim '{for (i = 1; i <= NF; i++) print $i}'
    return
  fi

  # resets delimvar to it's $RESET_XXX var
  if [[ $opt == "-r" ]]; then
    local reset_delimvar="RESET_$delimvar"
    export $delimvar=${!reset_delimvar}
    return
  fi

  # edit delimvar in vim with newlines as "temporary separators". :wq to save
  # changes, :q to discard changes
  if [[ $opt == "-e" ]]; then
    local temp=$(mktemp -t md_delimvar.XXXXXX)
    echo ${!delimvar} | awk -F$delim '{for (i = 1; i <= NF; i++) print $i}' > $temp
    vim $temp
    export $delimvar=$(cat $temp | tr '\n' $delim | sed "s/$delim$//g")
    rm $temp
    return
  fi

  # prepend/append needs atleast one argument
  if [[ $# -lt 1 ]]; then
    return
  fi

  # if delimvar is blank or not set
  if [[ ! $(echo ${!delimvar}) =~ [[:print:]]+ ]]; then
    if ! is_in_delimvar $delim $delimvar $1; then
      export $delimvar="$1"
    fi
    shift
    opt="-a" # XXX: Faking the option to force appending
  fi

  # prepend $@'s in reverse
  if [[ $opt == "-p" ]]; then
    for (( i=$#; i > 0; i-- )); do
      arg="${!i}"
      if ! is_in_delimvar $delim $delimvar $arg; then
        export $delimvar="${arg}${delim}${!delimvar}"
      fi
    done
  fi

  # appends $@'s as it is.
  if [[ $opt == "-a" ]]; then
    for arg in "$@"; do
      if ! is_in_delimvar $delim $delimvar $arg; then
        export $delimvar="${!delimvar}${delim}${arg}"
      fi
    done
  fi
}

function epath() {
  local opt=$1; shift;
  edelimvar ':' PATH $opt $(realpath "$@" 2> /dev/null);
}

function eld() {
  local opt=$1; shift;
  edelimvar ':' LD_LIBRARY_PATH $opt $(realpath "$@" 2> /dev/null);
}

function elb() {
  local opt=$1; shift;
  edelimvar ':' LIBRARY_PATH $opt $(realpath "$@" 2> /dev/null);
}

function ecpath() {
  local opt=$1; shift;
  edelimvar ':' CPATH $opt $(realpath "$@" 2> /dev/null);
}

function ind {
  $@ &
  disown $!
}

function pid2jid {
  jobs -l | gawk -v "_pid=$1" '$2 == _pid {print $1}' | \
    /bin/grep -oE "[[:digit:]]+"
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

  t_bg_curr_col="${t_bg_col[$cur]}"

  if [[ $cur == "wh" ]]; then
    t_fg_curr_col="${t_fg_col[bl]}"
  else
    t_fg_curr_col="${t_fg_col[wh]}"
  fi
}

# colors this pts
function cotty {
  [[ $# -ne 1 ]] && return
  echo $1 > ${t_col_path}
  _t_col_upd
}

# colors all pts
function coall {
  [[ $# -ne 1 ]] && return

  [[ ! -e "${t_col_path}" ]] || touch "${t_col_path}"
  echo $1 > ${t_col_path}
  _t_col_upd # updates the global vars

  for t in /dev/pts/*; do
    # skip this pts and ptmx, (the prompt will set color for this pts)
    if [[ $t == "$(tty)" || $t == "/dev/pts/ptmx" ]]; then
      continue
    fi

    exec 2> /dev/null
    echo -ne "${t_fg_curr_col}" > $t
    echo -ne "${t_bg_curr_col}" > $t
    exec 2> /dev/stdout
  done

  mkconf_gui $(echo $t_bg_curr_col | cut -c7-13)
  unset t
}

function prompt_command {
  # \e] are xterm OSC \e[ are VT100 ctrl seq

  # to set title
  echo -ne "\033]0; ${USER}@${HOSTNAME}[$(tty)]    ${PWD}\007"

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
  PS1+="\[${t_fg_curr_col}\]\[${t_bg_curr_col}\]"
}

function in_array {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

function vim {
  # we must hardcode /usr/bin/vim else we recurse!
  local vim_bin="/usr/bin/vim"

  [[ -x $HOME_BIN/vim ]] && vim_bin="$HOME_BIN/vim"

  # if $vim_bin has no client-server feature, then no fancy stuff
  if ! $vim_bin --version | /bin/grep -P '\+clientserver' 1> /dev/null; then
    $vim_bin -i NONE -p $@
    return
  fi

  local srv_name=$(tty)
  local cmd="$vim_bin -i NONE -p --servername $srv_name"
  if [[ $1 == "-" ]]; then
    $vim_bin -i NONE -
    return
  fi

  local bg_ps=$(ps -ef | /bin/grep -P "\s+$cmd")
  local bg_srv_name=/dev/$(echo $bg_ps | awk '{print $6}')
  local bg_pid=$(echo $bg_ps | awk '{print $2}')

  local args="" arg=""

  # if we have a non file arg and we have a bg_vim then run a new vim.
  for arg in "$@"; do
    if [[ ! -e $arg  && $bg_pid ]]; then
      $vim_bin "$@"
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

function dis {
  local bin=$1 asm; shift

  # Note that inling this at local-decl will make $asm ".s"
  asm=$(basename "$bin").s

  if file $bin | grep -iq "LLVM.*bitcode"; then
    asm="$bin.ll"
    llvm-dis $@ $bin -o $asm

  elif file $bin | grep -iq "ELF.*x86-64"; then
    objdump $@ -l -S -M intel -D -C $bin > $asm

  elif file $bin | grep -iq "ELF.*NVIDIA CUDA"; then
    nvdisasm $@ $bin > $asm
  fi

  vim $asm
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

    /bin/grep -P --color -n -I $exclude "$@"
  else
    /bin/grep -P --color -n -I "$@"
  fi
}

function cd {
  local srcroot=$(srcerer 2> /dev/null)
  if [[ -z "$srcroot" ]]; then
    command cd "$@"
    return
  fi

  local arg="$1"
  if [[ $arg == "" ]]; then
    command cd "$srcroot/"
    return
  fi

  command cd "$@"
}

function pacdry_fresh {
  local path_tmpdb=$(mktemp -t -d pacdry_tmpdb.XXXXXX)

  sudo pacman -Sy --dbpath "$path_tmpdb" --logfile /dev/null 1>&2 && \
    pacdry --dbpath "$path_tmpdb" "$@"
  sudo rm -rf "$path_tmpdb" &> /dev/null
}

function pacdry {
  sudo pacman --logfile /dev/null "$@"
}

function nt {
  local nt_dir="$HOME/documents/notes/sys/"
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
  local nt_dir="$HOME/documents/notes/sys/"
  local nt_comp=`ls $nt_dir | sed -r "/^\.+$/d"`
  local cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=( $(compgen -W "$nt_comp" -- $cur) )
}

# aliasing mn() unleashes hell when bashrc is sourced manually,
# so call it with mn, bash-completion done for it below
function mn {
  if [[ -e ~/.man-vimrc ]]; then
    man "$@" | ${EDITOR} -u ~/.man-vimrc -
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

function vocutil {
  local voc_db="$HOME/documents/notes/voc_db/"
  local run=$1; shift

  if [[ ! -d $voc_db ]]; then
    return
  fi

  if [[ $run == "def" ]]; then
    if [[ -e ${voc_db}  && $# -eq 1 ]]; then
      grep -inr --color $1 ${voc_db}/ 2> /dev/null
    fi
    return
  fi


  if [[ $run == "print" ]]; then
    local n=1
    if [[ $# -eq 1 ]]; then
      n=$1
    fi

    echo -e "\e[00;35m";
    type voc &> /dev/null && voc -r $n ${voc_db}
    echo -e "\e[0m";
  fi
}

function vimj {
  local hst=$(cat /etc/hostname)

  # Apr 24 20:42:21 localhost sudo[5336]:
  sudo journalctl --no-pager $* |
    grep -Pv  "^\w{3}\ \d{2}\ \d{2}:\d{2}:\d{2}\ $hst\ sudo\[\d+\].*$" | \
    ${EDITOR} -c "set filetype=messages" - "+normal G"
}

function crynt {
  local cry_dir="$HOME/eph/_x/"
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
  echo -n "cmdline: "
  echo `tr -d '\0' < /proc/$pid/cmdline` # else null bytes throw warn
  cd /proc/$pid
}

function clhome {
  local f
  for f in "$@"; do
    rm -rf ~/$f &> /dev/null
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
    rm ${f}.pdf ${f}.log ${f}.aux ${f}.pgf ${f}.toc &> /dev/null
  done
  rm missfont.log &> /dev/null
}

function harakiri {
  echo "pkill -u ${USER} ?"
  read
  pkill -u ${USER}
}

function psx {
  local type=$1; shift

  if [[ $type == "us" ]]; then
    local fields="flag,stat,euser,pid,ppid,pgid,sid,%mem,%cpu,"
    fields+="wchan=WIDE-WCHAN-COLUMN,tty,cmd"
  else
    local fields="flag,stat,pid,ppid,pri,ni,class,bsdtime,cmd"
  fi

  ps -o ${fields} $@
}

function am_i_home {
  if [[ -L /bin && $(hostname) =~ ppa\-.* ]]; then
    return 0
  fi
  return 1
}

if am_i_home; then
  function before_poweroff {
    mmrc -u chrome &> /dev/null
  }

  function poweroff { before_poweroff; /bin/poweroff; }

  function reboot { before_poweroff; /bin/reboot; }
fi

export TERM=xterm-256color
export VISUAL="/usr/bin/vim -i NONE" # disables ~/.viminfo
export EDITOR="$VISUAL" # use $EDITOR if "our" vim creates trouble
export ABINAV="thats my name, that name again - is Mr.Plow"
export MANSECT="2:3:1:8:9:5:4:7:0:n:l"
export HISTSIZE=8192
export HISTFILESIZE=8192
export EXTRA_BIN="$HOME/rc/run"
export HOME_BIN="$HOME/sys/usr/bin"
export HOME_LIB="$HOME/sys/usr/lib"
export HOME_INCLUDE="$HOME/sys/usr/include"
export PROJ="$HOME/proj"
export LLVM_DEV="$PROJ"
export FZF_DEFAULT_OPTS="--color 16" # we're used to this :)

edelimvar ':' PATH -a "."
epath -p "$HOME_BIN" "$EXTRA_BIN"
eld -p "$HOME_LIB"
elb -p "$HOME_LIB"
ecpath -p "$HOME_INCLUDE"

alias grep='grep -P --color -n'
alias srb='. ~/.bashrc'
alias ls='ls -a --color=auto --group-directories-first'
alias ll='/bin/ls -alih --color=auto --group-directories-first'
alias lt='/bin/ls -alihrt --color=auto'
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
alias dmesg='dmesg -T'
alias dmesge='dmesg -T --level alert,crit,emerg,err'
alias llvm-readobj-gnu='llvm-readobj --elf-output-style=GNU'
alias obd='objdump -M intel -D -C'
alias obd2='obd --visualize-jumps'

alias qtmux='tmux kill-server'
alias tmux='tmux -u -2'

alias cmus='TERM=xterm-256color cmus'

alias vimb="vim ~/.bashrc"
alias vimv="vim ~/.vimrc"
alias vimm="vim -u /etc/vimrc"

alias psu="psx us --ppid 2 -p 2 -N"
alias psi="psx us --ppid=1"
alias psk="psx ks --ppid 2 -p 2"
alias pss='ps -o unit,cmd --ppid 2 -p 2 -N'

if am_i_home; then
  source /usr/share/fzf/key-bindings.bash &> /dev/null
  source /usr/share/fzf/completion.bash &> /dev/null
else
  [[ -f ~/.fzf.bash ]] && source ~/.fzf.bash
fi

source /etc/.post-bashrc &> /dev/null
source ${HOME}/.post-bashrc &> /dev/null

# avoid re-setting RESET_XXX vars if sourcing .bashrc more than once
if [[ $_saved_RESET_XXX != true ]]; then
  export RESET_PATH=$PATH
  export RESET_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
  export RESET_LIBRARY_PATH=$LIBRARY_PATH
  export RESET_CPATH=$CPATH
  export _saved_RESET_XXX=true
fi

# If not running interactively
[[ $- != *i* ]] && return

t_col_path="$HOME/.t_col"

# Terminal colorscheme
t_bg_curr_col=
t_fg_curr_col=

_t_col_upd
mkconf_gui $(echo $t_bg_curr_col | cut -c7-13)

PROMPT_COMMAND=prompt_command

. /usr/share/bash-completion/completions/man &> /dev/null
. /usr/share/bash-completion/completions/pacman &> /dev/null
complete -F _man mn
complete -F _comp_nt nt
complete -F _pacman -o default pacdry

clhome .sw? .calc_history .lesshst Desktop .texlive .elinks .rnd .viminfo
print_fortune
vocutil print 1
