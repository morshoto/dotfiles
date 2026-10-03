autoload -Uz up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search

case_insensitive_up_line_or_beginning_search() {
  emulate -L zsh
  setopt NO_CASE_MATCH
  up-line-or-beginning-search
}

case_insensitive_down_line_or_beginning_search() {
  emulate -L zsh
  setopt NO_CASE_MATCH
  down-line-or-beginning-search
}

zle -N case_insensitive_up_line_or_beginning_search
zle -N case_insensitive_down_line_or_beginning_search
bindkey "^[[A" case_insensitive_up_line_or_beginning_search
bindkey "^[OA" case_insensitive_up_line_or_beginning_search
bindkey "^[[B" case_insensitive_down_line_or_beginning_search
bindkey "^[OB" case_insensitive_down_line_or_beginning_search
