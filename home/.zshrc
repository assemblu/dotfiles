export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git)

module_path=( "$HOME/.local/lib/zsh/5.9" )
_zfun="$HOME/.local/share/zsh/functions"
fpath=()
for _zdir in $_zfun/Completion/*(/); do fpath+=("$_zdir"); done
fpath+=(
  "$_zfun/Completion"
  $_zfun/Misc $_zfun/Zle $_zfun
)

source $ZSH/oh-my-zsh.sh

module_path=( "$HOME/.local/lib/zsh/5.9" )
fpath=()
for _zdir in $_zfun/Completion/*(/); do fpath+=("$_zdir"); done
fpath+=(
  "$_zfun/Completion"
  $_zfun/Misc $_zfun/Zle $_zfun
)
unset _zdir _zfun

autoload -U compinit compaudit is-at-least add-zsh-hook colors bashcompinit

source ~/.zsh_profile
