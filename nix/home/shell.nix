{ ... }:

{
  programs.zsh = {
    enable = true;

    shellAliases = {
      ll = "ls -al";
      gs = "git status";
      gc = "git commit";
      gp = "git push";
      k = "kubectl";
      tf = "terraform";
    };

    initExtra = ''
      export EDITOR="code --wait"
      export LANG="ja_JP.UTF-8"
    '';
  };

  programs.starship.enable = true;
  programs.zoxide.enable = true;
  programs.fzf.enable = true;
}
