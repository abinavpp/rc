[[ $- != *i* ]] && return # If not running interactively.

. /etc/.pre-bashrc &> /dev/null
. ${HOME}/.pre-bashrc &> /dev/null

alias ls='ls -a --color=auto --group-directories-first'
alias rm='rm -rfv'
alias cp='cp -vr'
alias grep='grep -P --color -n'
alias sudo='sudo '
alias readelf='readelf --wide'
alias gdb='gdb -q --args'
alias cmus='TERM=xterm-256color cmus'
alias tmux='tmux -u -2'
alias lsblk='lsblk -o +FSTYPE,STATE,TRAN,PHY-SEC,LOG-SEC,MODEL,UUID'
alias mkfs.ntfs='mkfs.ntfs -Q'

function eref() {
  [[ ! -d ~/.cache ]] && return 1

  local opt=$1; shift;
  local ref_dir=~/.cache/eref

  if [[ $opt == '-s' ]]; then
    mkdir $ref_dir 2> /dev/null

    (set -o posix; set > $ref_dir/variable)
    declare -f > $ref_dir/function
    set -o > $ref_dir/set
    shopt > $ref_dir/shopt
    alias > $ref_dir/alias
    return
  fi

  if [[ $opt == '-d' || $opt == '-D' ]]; then
    [[ ! -d $ref_dir ]] && return 1

    local filter_cmd
    printf -v filter_cmd '%s' 'sed -E /^(opt|filter_cmd|PPID|PWD|OLDPWD' \
      '|BASH_ARGC|BASH_ARGV|BASH_LINENO|BASH_REMATCH|BASH_SOURCE|COLUMNS' \
      '|LINES|FUNCNAME|TMUX_PANE|_fzf_.*|__fzf_.*|__git.*' \
      '|cur|prev|words|cword|PLUGIN)=/d'
    [[ $opt == '-D' ]] && filter_cmd='tee /dev/null'

    diff <(cat $ref_dir/variable | $filter_cmd) \
      <(set -o posix; set | $filter_cmd)

    diff <(cat $ref_dir/set) <(set -o)
    diff <(cat $ref_dir/shopt) <(shopt)
    diff <(cat $ref_dir/alias) <(alias)
    return
  fi

  if [[ $opt == '-f' ]]; then
    [[ ! -d $ref_dir ]] && return 1

    diff <(cat $ref_dir/function) <(declare -f)
  fi
}

alias sb='source ~/.bashrc; eref -d'

function is_in_delimvar() {
  declare -A fields
  local field
  local delim=$1 delimvar=$2 check=$3
  local fields=`echo ${!delimvar} | awk -F$delim \
    '{for (i = 1; i <= NF; i++) print $i}' | tr '\n' ' '`

  for field in ${fields[@]}; do
    if [[ $check == $field ]]; then
      return 0
    fi
  done
  return 1
}

function edelimvar() {
  if [[ $# -lt 3 ]]; then
    return
  fi

  local delim=$1 delimvar=$2 opt=$3; shift 3
  local arg i

  if [[ $opt == "-o" ]]; then
    # Print the delimvar.
    echo ${!delimvar} | awk -F$delim '{for (i = 1; i <= NF; i++) print $i}'
    return
  fi

  if [[ $opt == "-r" ]]; then
    # Reset delimvar to it's $RESET_XXX var.
    local reset_delimvar="RESET_$delimvar"
    export $delimvar=${!reset_delimvar}
    return
  fi

  if [[ $opt == "-e" ]]; then
    # Edit delimvar in the editor with newlines as a temporary delimiter where
    # saving the buffer while quitting saves changes but quitting without saving
    # discards changes.
    local temp=$(mktemp -t md_delimvar.XXXXXX)
    echo ${!delimvar} | awk -F$delim '{for (i = 1; i <= NF; i++) print $i}' > $temp
    $EDITOR $temp
    export $delimvar=$(cat $temp | tr '\n' $delim | sed "s/$delim$//g")
    /bin/rm $temp
    return
  fi

  # Prepend and append needs at least one argument.
  if [[ $# -lt 1 ]]; then
    return
  fi

  # If delimvar is blank or not set.
  if [[ ! $(echo ${!delimvar}) =~ [[:print:]]+ ]]; then
    if ! is_in_delimvar $delim $delimvar $1; then
      export $delimvar="$1"
    fi
    shift
    opt="-a" # XXX: Faking the option to force appending
  fi

  if [[ $opt == "-p" ]]; then
    # Prepend $@ in reverse.
    for (( i=$#; i > 0; i-- )); do
      arg="${!i}"
      if ! is_in_delimvar $delim $delimvar $arg; then
        export $delimvar="${arg}${delim}${!delimvar}"
      fi
    done
  fi

  if [[ $opt == "-a" ]]; then
    # Appends $@ as it is.
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

# Updates the global variables ${t_<fg/bg>_curr_col} as per the file name
# referred by ${t_col_path}.
function t_col_upd {
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

# Colors this pts.
function cotty {
  [[ $# -ne 1 ]] && return
  echo $1 > ${t_col_path}
  t_col_upd
}

# Colors all pts.
function coall {
  [[ $# -ne 1 ]] && return

  [[ ! -e "${t_col_path}" ]] || touch "${t_col_path}"
  echo $1 > ${t_col_path}
  t_col_upd # Updates the global variables.

  for t in /dev/pts/*; do
    # Skip this pts and ptmx, (the prompt will set color for this pts).
    if [[ $t == "$(tty)" || $t == "/dev/pts/ptmx" ]]; then
      continue
    fi

    exec 2> /dev/null
    echo -ne "${t_fg_curr_col}" > $t
    echo -ne "${t_bg_curr_col}" > $t
    exec 2> /dev/stdout
  done

  mkconf-gui $(echo $t_bg_curr_col | cut -c7-13)
  unset t
}

function prompt_command {
  # Refer `man console_codes`.

  # Recall that:
  # - \e[ is the CSI (Control Sequence Introducer) and the sequence following
  #   it is the CSI-sequence. The CSI-sequence ending in 'm' is the ECMA-48-SGR
  #   (Set Graphics Rendition).
  # - \e] is the OSC (Operating System Command) and the sequence following it
  #   is the OSC-sequence.
  # - Any non printable must be within \[ and \] in the PS1 string.

  PS1='[\j] ' # <num-jobs>
  PS1+='\[\e[38;5;76m\]\u@' # <user-name>@ in ECMA-48-SGR green foreground
  PS1+='\[\e[0m\]' # ECMA-48-SGR reset
  PS1+='\h ' # <host-name>
  PS1+='\W ' # <PWD>
  PS1+='\$ '

  t_col_upd
  PS1+="\[${t_fg_curr_col}\]\[${t_bg_curr_col}\]"
}

function pid_to_jid {
  jobs -l | gawk -v "_pid=$1" '$2 == _pid {print $1}' | \
    /bin/grep -oE "[[:digit:]]+"
}

function vim {
  local vim_bin="/usr/bin/vim"

  [[ -x $HOME_BIN/vim ]] && vim_bin="$HOME_BIN/vim"

  # If $vim_bin has no client-server feature.
  if ! $vim_bin --version | /bin/grep -q -P '\+clientserver'; then
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

  # If we have a non-file argument and we have a background vim then run a new
  # vim.
  for arg in "$@"; do
    if [[ ! -e $arg  && $bg_pid ]]; then
      $vim_bin "$@"
      return
    fi
  done

  if [[ $bg_pid ]]; then
    local bg_pwd=$(pwdx $bg_pid | awk '{print $2}')/
    for arg in "$@"; do
      arg=$(realpath "$arg")

      # If path is under $bg_pwd, then access it relative so that tab heading
      # will be neater.
      $cmd --remote-send "<esc>:tabnew ${arg##$bg_pwd} <CR>"
    done
    fg $(pid_to_jid $bg_pid)
    return

  else
    $cmd "$@"
  fi
}

function dis {
  local bin=$1 asm; shift

  # Note that inlining this at local declaration will make $asm ".s".
  asm=$(basename "$bin").s

  if file $bin | /bin/grep -iq "LLVM.*bitcode"; then
    asm="$bin.ll"
    llvm-dis $@ $bin -o $asm

  elif file $bin | /bin/grep -iq "ELF.*x86-64"; then

    # .o of a C++ file can have functions definitions in their own sections
    # whose names are of the form ".text.<function-name>". We add them to
    # objdump's -j. Note that the fully linked exe from C++ will have all it's
    # functions definitions in .text.
    local section sections
    for section in $(readelf -S $bin |\
      /bin/grep -Po '(?<=\ ).text.*?(?=\ )'); do
      sections="$sections -j $section"
    done

    obd $@ $sections $bin > $asm

  elif file $bin | /bin/grep -iq "ELF.*NVIDIA CUDA"; then
    nvdisasm $@ $bin > $asm
  fi

  vim $asm
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

function cdp {
  if [[ $# -ne 1 ]]; then
    return
  fi

  local pid=`pgrep $1 | head -n1`

  if [[ $pid == "" ]]; then
    return
  fi

  echo -n "cmdline: "
  echo `tr -d '\0' < /proc/$pid/cmdline`
  cd /proc/$pid
}

function rn {
  local tmp_file="$(mktemp -t tmp.XXXXXX)"

  ranger --choosedir="$tmp_file" "${@:-$(pwd)}"
  test -f "$tmp_file" &&
    if [[ "$(cat -- "$tmp_file")" != "$(echo -n `pwd`)" ]]; then
      cd -- "$(cat "$tmp_file")"
    fi

  /bin/rm -f -- "$tmp_file"
}

function xnt {
  local dir=$1 note=$2

  if [[ ! -e "$dir" ]]; then
    echo "$dir not set"
    return
  fi

  if [[ $# -ne 0  ]]; then
    vim "$dir/$note"
  else
    ls "$dir"
  fi
}
function nt { xnt "$HOME/doc/cs/sys" $1; }
function cmpnt { xnt "$HOME/doc/cs/comp" $1; }
function scrnt { xnt "$HOME/doc/misc/scratch" $1; }
function culnt { xnt "$HOME/doc/cul" $1; }

function _comp_xnt() {
  local dir=$1

  [[ ! -d $dir ]] && return

  cd $dir;
  local words=`git ls-files 2> /dev/null`
  [[ -z $words ]] && words=`find * -type f -print 2> /dev/null`
  cd - &> /dev/null

  local cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=( $(compgen -W "$words" -- $cur) )
}
function _comp_nt() { _comp_xnt $HOME/doc/cs/sys; }
function _comp_cmpnt() { _comp_xnt $HOME/doc/cs/comp; }
function _comp_scrnt() { _comp_xnt $HOME/doc/misc/scratch; }
function _comp_culnt() { _comp_xnt $HOME/doc/cul; }

export TERM=xterm-256color
export VISUAL="/usr/bin/vim -i NONE" # Disables ~/.viminfo
export EDITOR="$VISUAL" # Use $EDITOR if `function vim` creates trouble
export MANSECT="2:3:1:8:9:5:4:7:0:n:l"
export HISTSIZE=32768
export HISTFILESIZE=32768
export EXTRA_BIN="$HOME/rc/run"
export HOME_BIN="$HOME/sys/usr/bin"
export HOME_LIB="$HOME/sys/usr/lib"
export HOME_INCLUDE="$HOME/sys/usr/include"
export PROJ="$HOME/proj"
export LLVM_DEV="$PROJ"
export FZF_DEFAULT_OPTS="--color 16"
export LESSHISTFILE=/dev/null
export QT_QPA_PLATFORMTHEME=qt5ct

edelimvar ':' PATH -a "."
epath -p "$HOME_BIN" "$EXTRA_BIN"
eld -p "$HOME_LIB"
elb -p "$HOME_LIB"
ecpath -p "$HOME_INCLUDE"

# Terminal color-scheme:
declare -A t_bg_col t_fg_col
t_bg_col[bl]="\e]11;#000000\007"
t_bg_col[dk]="\e]11;#3a3a3a\007"
t_bg_col[wh]="\e]11;#ffffff\007"
t_bg_col[mg]="\e]11;#520348\007"
t_bg_col[gr]="\e]11;#08150f\007"
t_bg_col[bu]="\e]11;#031721\007"
t_fg_col[bl]="\e]10;#000000\007"
t_fg_col[wh]="\e]10;#ffffff\007"
t_fg_col[rd]="\e]10;#b20000\007"
t_fg_col[gr]="\e]10;#008000\007"

t_col_path="$HOME/.t_col"
t_bg_curr_col=
t_fg_curr_col=

prompt_command
PROMPT_COMMAND=prompt_command

# Enable fzf for Arch Linux.
. /usr/share/fzf/completion.bash &> /dev/null
. /usr/share/fzf/key-bindings.bash &> /dev/null

# Enable fzf for Ubuntu.
. /usr/share/doc/fzf/examples/completion.bash &> /dev/null
. /usr/share/doc/fzf/examples/key-bindings.bash &> /dev/null

# Enable fzf for local installation.
. ~/.fzf.bash &> /dev/null

. /usr/share/bash-completion/completions/git &> /dev/null
. /usr/share/bash-completion/completions/man &> /dev/null
. /usr/share/bash-completion/completions/pacman &> /dev/null
__git_complete gitr __git_main
__git_complete gitrq __git_main
__git_complete gitbr __git_main
complete -F _man mn
complete -F _comp_nt nt
complete -F _comp_cmpnt cmpnt
complete -F _comp_scrnt scrnt
complete -F _comp_culnt culnt
complete -F _pacman -o default pacdry

t_col_upd
mkconf-gui $(echo $t_bg_curr_col | cut -c7-13)
clhome

. /etc/.post-bashrc &> /dev/null
. ${HOME}/.post-bashrc &> /dev/null

# Avoid resetting RESET_XXX variables if sourcing .bashrc more than once.
if [[ $SAVED_RESET_XXX != true ]]; then
  export RESET_PATH=$PATH
  export RESET_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
  export RESET_LIBRARY_PATH=$LIBRARY_PATH
  export RESET_CPATH=$CPATH
  export SAVED_RESET_XXX=true
fi
