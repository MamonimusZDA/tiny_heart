#! /usr/bin/env zsh

#
# Standarized $0 handling
# https://github.com/zdharma/Zsh-100-Commits-Club/blob/master/Zsh-Plugin-Standard.adoc
#

0=${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}
0=${${(M)0:#/*}:-$PWD/$0}

typeset -gA TinyHrt
TinyHrt[root]=${0:A:h}

#
# Options
#

## Color definition ##

# Color definition for command's exit status
: ${TINYHRT_COLOR_FG_EXITSTATUS_OK:=44}
: ${TINYHRT_COLOR_FG_EXITSTATUS_NO:=204}

# Icon's color definition for command's exit status
: ${TINYHRT_COLOR_FG_EXITSTATUS_OK_ICON:=255}
: ${TINYHRT_COLOR_FG_EXITSTATUS_NO_ICON:=1}

# Color definition for active directory name
: ${TINYHRT_COLOR_FG_DIR:=63}

# Color definition for time execution command
: ${TINYHRT_COLOR_FG_TEXC:=50}

# Color definition for prompt when a command is executed
: ${TINYHRT_COLOR_FG_SWAP_PROMPT:=175}

# Color definition for Git branch or pid
: ${TINYHRT_COLOR_FG_GITINFO:=61}

# Color definition for Git remote repository icon
: ${TINYHRT_COLOR_FG_GITINFO_REMOTE_ICON:=63}

# Color definition for Git info
: ${TINYHRT_COLOR_FG_GITINFO_AHEAD:=43}
: ${TINYHRT_COLOR_FG_GITINFO_BEHIND:=210}
: ${TINYHRT_COLOR_FG_GITINFO_UNTRACKED:=175}
: ${TINYHRT_COLOR_FG_GITINFO_UNMERGED:=111}
: ${TINYHRT_COLOR_FG_GITINFO_STAGED:=43}
: ${TINYHRT_COLOR_FG_GITINFO_UNSTAGED:=175}
: ${TINYHRT_COLOR_FG_GITINFO_STASHED:=111}

## Icon definition ##

# Icon definition for command's exit status
: ${TINYHRT_EXITSTATUS_OK_ICON:="󰣐"}
: ${TINYHRT_EXITSTATUS_NO_ICON:="󰋔"}

# Icon definition for time execution command
: ${TINYHRT_TEXC_ICON:="󰔟"}

# Icon definition for active directory name
: ${TINYHRT_HOME_DIR_ICON:=""}
: ${TINYHRT_ROOT_DIR_ICON:=""}
: ${TINYHRT_OTHER_DIR_ICON:=""}

# Icon definition for close the prompt
: ${TINYHRT_PROMPT_CLOSE_ICON:=""}

# Icon definition for prompt when a command is executed
: ${TINYHRT_SWAP_PROMPT_ICON:="󰋷"}

# Icon definition for Git remote repository icon
: ${TINYHRT_GITINFO_GITHUB_ICON:=""}
: ${TINYHRT_GITINFO_GITLAB_ICON:="󰮠"}
: ${TINYHRT_GITINFO_BITBUCKET_ICON:=""}
: ${TINYHRT_GITINFO_LOCAL_ICON:=""}
: ${TINYHRT_GITINFO_OTHER_ICON:=""}

# Icon definition for Git info
: ${TINYHRT_GITINFO_AHEAD_ICON:="⇡"}
: ${TINYHRT_GITINFO_BEHIND_ICON:="⇣"}
: ${TINYHRT_GITINFO_UNTRACKED_ICON:="?"}
: ${TINYHRT_GITINFO_UNMERGED_ICON:="~"}
: ${TINYHRT_GITINFO_STAGED_ICON:="+"}
: ${TINYHRT_GITINFO_UNSTAGED_ICON:="!"}
: ${TINYHRT_GITINFO_STASHED_ICON:="*"}

## Variable definition ##

# Minimal time (in ms) for the time execution of command is displayed in prompt
: ${TINYHRT_TEXC_MIN_MS:=5}

# Option whether drawing a gap between a prompt
: ${TINYHRT_PROMPT_HAS_GAP:=true}

# Max size of terminal (in colums) for break the prompt
: ${TINYHRT_TERM_SIZE_TO_TRUNCATE:=60}

#
# Modules
#

# Get information from active git repo
tinyHrt_get_gitinfo() {
  cd -q "$1"

  git rev-parse --is-inside-work-tree &>/dev/null && {
    local gitinfo=""
    local gitRmt=$(git remote --verbose | awk 'NR==1{print $2}')
    gitRmt=${${${gitRmt##*https://}%%.*}:-local}

    local gitRmtIcon=""
    case "${gitRmt}" in
      local) gitRmtIcon="${TINYHRT_GITINFO_LOCAL_ICON}" ;;
      *github*) gitRmtIcon="${TINYHRT_GITINFO_GITHUB_ICON}" ;;
      *gitlab*) gitRmtIcon="${TINYHRT_GITINFO_GITLAB_ICON}" ;;
      *bitbucket*) gitRmtIcon="${TINYHRT_GITINFO_BITBUCKET_ICON}" ;;
      *) gitRmtIcon="${TINYHRT_GITINFO_OTHER_ICON}" ;;
    esac

    gitinfo+="%F{${TINYHRT_COLOR_FG_GITINFO_REMOTE_ICON}}${gitRmtIcon}%F{reset} "
    source "${TinyHrt[root]}/lib/async.zsh"
    gitinfo+=$(git status --branch --porcelain=v2 | awk \
      -f ${TinyHrt[root]}/misc/gitinfo.awk \
      -v AHEAD_ICON="${TINYHRT_GITINFO_AHEAD_ICON}" \
      -v BEHIND_ICON="${TINYHRT_GITINFO_BEHIND_ICON}" \
      -v UNTRACKED_ICON="${TINYHRT_GITINFO_UNTRACKED_ICON}" \
      -v UNMERGED_ICON="${TINYHRT_GITINFO_UNMERGED_ICON}" \
      -v STAGED_ICON="${TINYHRT_GITINFO_STAGED_ICON}" \
      -v UNSTAGED_ICON="${TINYHRT_GITINFO_UNSTAGED_ICON}" \
      -v STASHED_ICON="${TINYHRT_GITINFO_STASHED_ICON}" \
      -v COLOR_INFO="${TINYHRT_COLOR_FG_GITINFO}" \
      -v COLOR_AHEAD="${TINYHRT_COLOR_FG_GITINFO_AHEAD}" \
      -v COLOR_BEHIND="${TINYHRT_COLOR_FG_GITINFO_BEHIND}" \
      -v COLOR_UNTRACKED="${TINYHRT_COLOR_FG_GITINFO_UNTRACKED}" \
      -v COLOR_UNMERGED="${TINYHRT_COLOR_FG_GITINFO_UNMERGED}" \
      -v COLOR_STAGED="${TINYHRT_COLOR_FG_GITINFO_STAGED}" \
      -v COLOR_UNSTAGED="${TINYHRT_COLOR_FG_GITINFO_UNSTAGED}" \
      -v COLOR_STASHED="${TINYHRT_COLOR_FG_GITINFO_STASHED}" \
      -v RC="%F{reset}")

    printf -- '%s' "${gitinfo}"
  } || return 0
}

# Manage time of command execution
tinyHrt_get_texc() {
  (( TINYHRT_TEXC_MIN_MS )) && (( ${TinyHrt[raw_texc]} )) || return
  local duration=$(( EPOCHSECONDS - ${TinyHrt[raw_texc]} ))
  (( duration >= TINYHRT_TEXC_MIN_MS )) && {
    local moment d h m s

    d=$(( duration / 60 / 60 / 24 ))
    h=$(( duration / 60 / 60 % 24 ))
    m=$(( duration / 60 % 60 ))
    s=$(( duration % 60 ))

    (( d )) && moment+="${d}d"
    (( h )) && moment+="${h}h"
    (( m )) && moment+="${m}m"
    moment+="${s}s"

    printf -- '%s' "%F{${TINYHRT_COLOR_FG_TEXC}}%B${TINYHRT_TEXC_ICON} ${moment}%b%F{reset}"
  }
}

# Working directory info
tinyHrt_get_dir() {
  local pth=$(sed "s#\([^a-z]*[a-z]\)[^/]*/#\1/#g" <<< "${PWD/#${HOME}/~}")
  pth=${pth// /\\}
  local dirs=("${${(@s:/:)pth}[@]#}")

  local SS="%F{$TINYHRT_COLOR_FG_DIR}%B"$'%{\001\x1b[3m\002%}'
  local SE=$'%{\001\x1b[0m\002%}'"%b%F{$((TINYHRT_COLOR_FG_DIR - 2))}"

  ((${#dirs[@]} - 1)) && [ -n "${dirs[-1]}" ] && dirs[-1]="${SS}${dirs[-1]}${SE}"
  [ -n "${dirs[1]}" ] && dirs[1]="${SS}${dirs[1]}${SE}" || {
    dirs[1]="${SS}${dirs[1]}"
    dirs[2]="${dirs[2]}${SE}"
  }

  case "${PWD}"; in
    "${HOME}") local icon="${TINYHRT_HOME_DIR_ICON} " ;;
    "${HOME}"*) local icon="${TINYHRT_OTHER_DIR_ICON} " ;;
    *) local icon="${TINYHRT_ROOT_DIR_ICON} " ;;
  esac

  printf -- '%s' "%F{$TINYHRT_COLOR_FG_DIR}${icon}${${${dirs[*]// //}//\\/ }/^\%B\%b\//%B/%b}%F{reset}"
}

# Command's exit status decoration
tinyHrt_get_status() {
  local status_ok="%F{${TINYHRT_COLOR_FG_EXITSTATUS_OK}}"
  status_ok+="{ %F{${TINYHRT_COLOR_FG_EXITSTATUS_OK_ICON}}"
  status_ok+="${TINYHRT_EXITSTATUS_OK_ICON} "
  status_ok+="%F{${TINYHRT_COLOR_FG_EXITSTATUS_OK}}}"

  local status_no="%F{${TINYHRT_COLOR_FG_EXITSTATUS_NO}}"
  status_no+="{ %F{${TINYHRT_COLOR_FG_EXITSTATUS_NO_ICON}}"
  status_no+="${TINYHRT_EXITSTATUS_NO_ICON} "
  status_no+="%F{${TINYHRT_COLOR_FG_EXITSTATUS_NO}}}"

  printf -- '%s' "%(?:${status_ok}:${status_no})%F{reset}"
}

#
# Build the prompt
#

tinyHrt_prompt_left() {
  local p="${TinyHrt[data_status]} "
  p+="${TinyHrt[data_dir]} "
  [ -n "${TinyHrt[data_texc]}" ] && p+="${TinyHrt[data_texc]} "

  p='%-'$TINYHRT_TERM_SIZE_TO_TRUNCATE'(l:'$p$TINYHRT_PROMPT_CLOSE_ICON' :┌─'$p$'\n└ )'

  TinyHrt[lprompt]=$p
  typeset -g PROMPT=${TinyHrt[lprompt]}
}

tinyHrt_prompt_right() {
  local p=""
  [ -n "${TinyHrt[data_gitinfo]}" ] && p+="${TinyHrt[data_gitinfo]}"

  TinyHrt[rprompt]=$p
  typeset -g RPROMPT=${TinyHrt[rprompt]}
}

tinyHrt_draw_prompts() {
  TinyHrt[data_status]=$(tinyHrt_get_status)
  TinyHrt[data_dir]=$(tinyHrt_get_dir)

  tinyHrt_prompt_left
  tinyHrt_prompt_right

  typeset -g PS2="  "
}

#
# Async
#

# Initialize async
tinyHrt_async_init() {
  async_init 2>/dev/null || {
    source "${TinyHrt[root]}/lib/async.zsh"
    async_init
  }

  async_start_worker tinyhrtworker -n
  async_worker_eval tinyhrtworker builtin cd -q $PWD
  async_register_callback tinyhrtworker tinyHrt_async_callback
}

# Callback functions for async worker
tinyHrt_async_callback() {
  TinyHrt[data_${1/tinyHrt_get_/}]=$3

  tinyHrt_draw_prompts
  zle && zle reset-prompt
}

#
# Zsh functions
#

tinyHrt_preexec() {
  [[ "$1" = (clear|reset) ]] && TinyHrt[draw_gap]=false
  TinyHrt[raw_texc]=$EPOCHSECONDS
}

tinyHrt_precmd() {
  tinyHrt_precmd() {
    ( ${TinyHrt[draw_gap]} ) && print
    TinyHrt[draw_gap]=$TINYHRT_PROMPT_HAS_GAP
  }
}

tinyHrt_line_init() {
  TinyHrt[data_texc]=$(tinyHrt_get_texc)
  zpty -t tinyhrtworker &>/dev/null &&
    async_job tinyhrtworker tinyHrt_get_gitinfo $PWD ||
    TinyHrt[data_gitinfo]=$(tinyHrt_get_gitinfo $PWD)

  tinyHrt_draw_prompts
  zle reset-prompt

  TinyHrt[raw_texc]=0
}

tinyHrt_line_finish() {
  TinyHrt[swap_lprompt]="%F{${TINYHRT_COLOR_FG_SWAP_PROMPT}}${TINYHRT_SWAP_PROMPT_ICON} %F{reset} "
  typeset -g PROMPT=${TinyHrt[swap_lprompt]}
  typeset -g RPROMPT=""

  zle reset-prompt
}

#
# Main Setup
#

tinyHrt_main() {
  TinyHrt[saved_lprompt]=$PROMPT
  TinyHrt[saved_rprompt]=$RPROMPT
  TinyHrt[saved_promptsubst]=${options[promptsubst]}
  TinyHrt[saved_promptbang]=${options[promptbang]}

  setopt prompt_subst
  autoload -Uz add-zsh-hook add-zle-hook-widget

  (( $+EPOCHSECONDS )) || zmodload zsh/datetime

  tinyHrt_async_init

  add-zsh-hook preexec tinyHrt_preexec
  add-zsh-hook precmd tinyHrt_precmd

  add-zle-hook-widget zle-line-finish tinyHrt_line_finish
  add-zle-hook-widget zle-line-init tinyHrt_line_init
}

#
# Unload function
# https://github.com/zdharma/Zsh-100-Commits-Club/blob/master/Zsh-Plugin-Standard.adoc#unload-fun
#

tinyHrt_plugin_unload() {
  [[ ${TinyHrt[saved_promptsubst]} == 'off' ]] && unsetopt prompt_subst
  [[ ${TinyHrt[saved_promptbang]} == 'on' ]] && setopt prompt_bang

  PROMPT=${TinyHrt[saved_lprompt]}

  add-zsh-hook -D preexec tinyHrt_preexec
  add-zsh-hook -D precmd tinyHrt_precmd

  unfunction \
    tinyHrt_get_gitinfo \
    tinyHrt_get_texc \
    tinyHrt_get_dir \
    tinyHrt_get_status \
    tinyHrt_prompt_left \
    tinyHrt_prompt_right \
    tinyHrt_draw_prompts \
    tinyHrt_async_init \
    tinyHrt_async_callback \
    tinyHrt_preexec \
    tinyHrt_precmd \
    tinyHrt_line_init \
    tinyHrt_line_finish \
    tinyHrt_main

  unset \
    TINYHRT_COLOR_FG_EXITSTATUS_OK \
    TINYHRT_COLOR_FG_EXITSTATUS_NO \
    TINYHRT_COLOR_FG_EXITSTATUS_OK_ICON \
    TINYHRT_COLOR_FG_EXITSTATUS_NO_ICON \
    TINYHRT_COLOR_FG_TEXC \
    TINYHRT_COLOR_FG_DIR \
    TINYHRT_COLOR_FG_SWAP_PROMPT \
    TINYHRT_COLOR_FG_GITINFO \
    TINYHRT_COLOR_FG_GITINFO_AHEAD \
    TINYHRT_COLOR_FG_GITINFO_BEHIND \
    TINYHRT_COLOR_FG_GITINFO_UNTRACKED \
    TINYHRT_COLOR_FG_GITINFO_UNMERGED \
    TINYHRT_COLOR_FG_GITINFO_STAGED \
    TINYHRT_COLOR_FG_GITINFO_UNSTAGED \
    TINYHRT_COLOR_FG_GITINFO_STASHED \
    TINYHRT_EXITSTATUS_OK_ICON \
    TINYHRT_EXITSTATUS_NO_ICON \
    TINYHRT_TEXC_ICON \
    TINYHRT_HOME_DIR_ICON \
    TINYHRT_ROOT_DIR_ICON \
    TINYHRT_OTHER_DIR_ICON \
    TINYHRT_PROMPT_CLOSE_ICON \
    TINYHRT_SWAP_PROMPT_ICON \
    TINYHRT_GITINFO_GITHUB_ICON \
    TINYHRT_GITINFO_GITLAB_ICON \
    TINYHRT_GITINFO_BITBUCKET_ICON \
    TINYHRT_GITINFO_LOCAL_ICON \
    TINYHRT_GITINFO_OTHER_ICON \
    TINYHRT_GITINFO_AHEAD_ICON \
    TINYHRT_GITINFO_BEHIND_ICON \
    TINYHRT_GITINFO_UNTRACKED_ICON \
    TINYHRT_GITINFO_UNMERGED_ICON \
    TINYHRT_GITINFO_STAGED_ICON \
    TINYHRT_GITINFO_UNSTAGED_ICON \
    TINYHRT_GITINFO_STASHED_ICON \
    TINYHRT_TEXC_MIN_MS \
    TINYHRT_PROMPT_HAS_GAP \
    TINYHRT_TERM_SIZE_TO_TRUNCATE \
    TinyHrt

  unfunction $0
}

tinyHrt_main "${@}"
