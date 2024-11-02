[[ $- != *i* ]] && return # If not running interactively.

. /etc/.pre-bashrc &> /dev/null
. ${HOME}/.pre-bashrc &> /dev/null

alias ls='ls -a --color=auto --group-directories-first'
alias rm='rm -rfv'
alias cp='cp -vr'
alias grep='grep -P --color -n'
alias vimdiff='vimdiff -i NONE'
alias sudo='sudo '
alias readelf='readelf --wide'
alias gdb='gdb -q --args'
alias cmus='TERM=xterm-256color cmus'
alias tmux='tmux -u -2'
alias lsblk='lsblk -o NAME,MOUNTPOINTS,SIZE,UUID,LABEL,MODEL,FSTYPE,STATE,TRAN,PHY-SEC,LOG-SEC'
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
      '|LINES|FUNCNAME|TMUX|WINDOWID|TMUX_PANE|_.*' \
      '|cur|prev|words|cword|arg|PLUGIN)=/d'
    [[ $opt == '-D' ]] && filter_cmd='tee /dev/null'
    diff <(cat $ref_dir/variable | $filter_cmd) \
      <(set -o posix; set | $filter_cmd)

    filter_cmd='sed -E /^complete_fullquote[[:space:]]/d'
    [[ $opt == '-D' ]] && filter_cmd='tee /dev/null'
    diff <(cat $ref_dir/shopt | $filter_cmd ) <(shopt | $filter_cmd)

    diff <(cat $ref_dir/set) <(set -o)
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
    echo ${!delimvar} | awk -F$delim \
      '{for (i = 1; i <= NF; i++) print $i}' > $temp
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
    opt="-a" # XXX: Faking the option to force appending.
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
  [[ -z $PATH ]] && unset PATH
}

function eld() {
  local opt=$1; shift;
  edelimvar ':' LD_LIBRARY_PATH $opt $(realpath "$@" 2> /dev/null);
  [[ -z $LD_LIBRARY_PATH ]] && unset LD_LIBRARY_PATH
}

function elb() {
  local opt=$1; shift;
  edelimvar ':' LIBRARY_PATH $opt $(realpath "$@" 2> /dev/null);
  [[ -z $LIBRARY_PATH ]] && unset LIBRARY_PATH
}

function ecpath() {
  local opt=$1; shift;
  edelimvar ':' CPATH $opt $(realpath "$@" 2> /dev/null);
  [[ -z $CPATH ]] && unset CPATH
}

function vim {
  local vim_bin="/usr/bin/vim"
  [[ -x ~/.local/bin/vim ]] && vim_bin=~/.local/bin/vim

  # If $vim_bin has no client-server feature.
  if ! $vim_bin --version | /bin/grep -q -P '\+clientserver'; then
    $vim_bin -i NONE "$@"
    return
  fi

  if [[ $1 == "-" ]]; then
    $vim_bin -i NONE -
    return
  fi

  local cmd="$vim_bin -i NONE --servername $(tty)"
  local bg_pid=$(pgrep -f "$cmd")
  local args="" arg=""

  # If we have a non-file argument and we have a background vim then run a new
  # vim.
  for arg in "$@"; do
    if [[ ! -e $arg  && $bg_pid ]]; then
      $vim_bin -i NONE "$@"
      return
    fi
  done

  if [[ $bg_pid ]]; then
    for arg in "$@"; do
      arg=$(realpath "$arg")
      $cmd --remote-send "<Esc>:e $arg<CR>"
    done

    fg $(jobs -l | gawk -v "pid=$bg_pid" '$2 == pid {print $1}' | \
      /bin/grep -oE "[[:digit:]]+")
    return

  else
    $cmd "$@"
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

function rn {
  local tmp_file="$(mktemp -t tmp.XXXXXX)"

  ranger --choosedir="$tmp_file" "${@:-$(pwd)}"
  test -f "$tmp_file" &&
    if [[ "$(cat -- "$tmp_file")" != "$(echo -n `pwd`)" ]]; then
      cd -- "$(cat "$tmp_file")"
    fi

  /bin/rm -f -- "$tmp_file"
}

function sysnt { vim "$HOME/doc/cs/sys/$1"; }
function cmpnt { vim "$HOME/doc/cs/cmp/$1"; }
function scrnt { vim "$HOME/doc/scr/$1"; }
function culnt { vim "$HOME/doc/cul/$1"; }

function _comp_nt() {
  local dir=$1

  [[ ! -d $dir ]] && return

  cd $dir;
  local words=`git ls-files 2> /dev/null`
  [[ -z $words ]] && words=`find * -type f -print 2> /dev/null`
  cd - &> /dev/null

  local cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=( $(compgen -W "$words" -- $cur) )
}

function _comp_sysnt() { _comp_nt ~/doc/cs/sys; }
function _comp_cmpnt() { _comp_nt ~/doc/cs/cmp; }
function _comp_scrnt() { _comp_nt ~/doc/scr; }
function _comp_culnt() { _comp_nt ~/doc/cul; }

set -o ignoreeof
shopt -s histappend extglob
PROMPT_COMMAND='history -a'
export HISTSIZE=32768
export HISTFILESIZE=32768
PS1='[\j] \W \[\e[38;5;76m\]$([[ -n `eref -d` ]] && echo \*)$\[\e[0m\] '
export TERM=xterm-256color
export VISUAL="/usr/bin/vim -i NONE" # Disables ~/.viminfo.
export EDITOR="$VISUAL" # Use $EDITOR if `function vim` creates trouble.
export MANSECT="2:3:1:8:9:5:4:7:0:n:l"
export FZF_DEFAULT_OPTS="--color 16"
export LESSHISTFILE=/dev/null
edelimvar ':' PATH -a "."
edelimvar ':' PATH -p ~/bin ~/.local/bin ~/rc/bin ~/.vim/plugged/fzf/bin

. ~/.vim/plugged/fzf/shell/key-bindings.bash &> /dev/null
. /usr/share/bash-completion/completions/git &> /dev/null
. /usr/share/bash-completion/completions/man &> /dev/null
. /usr/share/bash-completion/completions/pacman &> /dev/null
__git_complete gitr __git_main &> /dev/null
__git_complete gitrq __git_main &> /dev/null
__git_complete gitfr git_checkout &> /dev/null
complete -F _comp_cmd_man mn
complete -F _comp_sysnt sysnt
complete -F _comp_cmpnt cmpnt
complete -F _comp_scrnt scrnt
complete -F _comp_culnt culnt
complete -F _pacman -o default pacdry

. /etc/.post-bashrc &> /dev/null
. ${HOME}/.post-bashrc &> /dev/null

# Avoid resetting RESET_XXX variables if sourcing .bashrc more than once.
if [[ $SAVED_RESET_XXX != true ]]; then
  export RESET_PATH="$PATH"
  export RESET_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
  export RESET_LIBRARY_PATH="$LIBRARY_PATH"
  export RESET_CPATH="$CPATH"
  export SAVED_RESET_XXX=true
fi
