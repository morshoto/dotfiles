{ config, ... }:

{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;

    initContent = ''
      source "$HOME/.config/zsh/environment.zsh"
      source "$HOME/.config/zsh/aliases.zsh"
      source "$HOME/.config/zsh/keybindings.zsh"
      source "$HOME/.config/zsh/completion.zsh"
      source "$HOME/.config/zsh/integrations.zsh"

      if [ -f "$HOME/.config/zsh/extra.zsh" ]; then
        source "$HOME/.config/zsh/extra.zsh"
      fi

      if [ -f "$HOME/.config/zsh/local.zsh" ]; then
        source "$HOME/.config/zsh/local.zsh"
      fi

      source "$HOME/.config/zsh/home-manager.zsh"
    '';
  };

  programs.zoxide.enable = true;
  programs.fzf.enable = true;
}
