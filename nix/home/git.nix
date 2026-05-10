{ ... }:

{
  programs.git = {
    enable = true;
    userName = "morshoto";
    userEmail = "jojoto8845@icloud.com";

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
      core.editor = "code --wait";
    };

    ignores = [
      ".DS_Store"
      ".direnv"
      ".env"
      "result"
      "result-*"
    ];
  };
}
