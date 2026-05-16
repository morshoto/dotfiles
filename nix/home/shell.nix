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
      zle -N up-line-or-beginning-search
      zle -N down-line-or-beginning-search
      bindkey "^[[A" up-line-or-beginning-search
      bindkey "^[OA" up-line-or-beginning-search
      bindkey "^[[B" down-line-or-beginning-search
      bindkey "^[OB" down-line-or-beginning-search

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
