{ config, ... }:

{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;

    initContent = builtins.readFile ../../zsh/init.zsh;
  };

  programs.zoxide.enable = true;
  programs.fzf.enable = true;
}
