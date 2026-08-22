if [[ ! "$PATH" == */tmp/fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/tmp/fzf/bin"
fi

eval "$(fzf --bash)"
