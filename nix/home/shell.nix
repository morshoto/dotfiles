{ config, ... }:

{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;

    shellAliases = {
      ll = "ls -al";
      gs = "git status";
      gc = "git commit";
      gp = "git push";
      k = "kubectl";
      tf = "terraform";
    };

    initContent = ''
      export EDITOR="code --wait"
      export LANG="ja_JP.UTF-8"

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

      # Make shell completion and fzf matching case-insensitive.
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
      if [ -n "$FZF_DEFAULT_OPTS" ]; then
        export FZF_DEFAULT_OPTS="--case-insensitive $FZF_DEFAULT_OPTS"
      else
        export FZF_DEFAULT_OPTS="--case-insensitive"
      fi

      if [ -f "$HOME/powerlevel10k/powerlevel10k.zsh-theme" ]; then
        source "$HOME/powerlevel10k/powerlevel10k.zsh-theme"
      fi

      if [ -f "$HOME/.p10k.zsh" ]; then
        source "$HOME/.p10k.zsh"
        # typeset -g POWERLEVEL9K_DIR_BACKGROUND=24
        # typeset -g POWERLEVEL9K_DIR_FOREGROUND=255
        # typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=153
        # typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=255
      fi

      if [ -f "$HOME/.config/zsh/extra.zsh" ]; then
        source "$HOME/.config/zsh/extra.zsh"
      fi
    '';
  };

  programs.zoxide.enable = true;
  programs.fzf.enable = true;
}
