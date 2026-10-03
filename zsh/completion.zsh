# Make shell completion and fzf matching case-insensitive.
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
if [[ -n "${FZF_DEFAULT_OPTS:-}" ]]; then
  export FZF_DEFAULT_OPTS="--case-insensitive $FZF_DEFAULT_OPTS"
else
  export FZF_DEFAULT_OPTS="--case-insensitive"
fi
