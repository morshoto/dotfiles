{ ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "morshoto";
        email = "jojoto8845@icloud.com";
      };

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
