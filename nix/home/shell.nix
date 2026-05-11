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

      if [ -f "$HOME/.config/zsh/extra.zsh" ]; then
        source "$HOME/.config/zsh/extra.zsh"
      fi
    '';
  };

  programs.starship.enable = true;
  programs.zoxide.enable = true;
  programs.fzf.enable = true;
}
