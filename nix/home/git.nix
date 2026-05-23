{ ... }:

{
  # programs.delta.enable = true;
  programs.delta.enableGitIntegration = true;
  programs.git.lfs.enable = true;

  programs.git = {
    enable = true;

    settings = {
      branch.sort = "-committerdate";

      commit.verbose = true;

      credential.helper = "gh auth git-credential";

      core.editor = "code --wait";
      core.pager = "less --mouse --wheel-lines=3 -R";

      # diff.colorMoved = "default";

      fetch.prune = true;
      fetch.pruneTags = true;
      fetch.writeCommitGraph = true;

      gpg.format = "ssh";

      init.defaultBranch = "main";

      merge.conflictStyle = "zdiff3";

      pull.rebase = false;

      push.autoSetupRemote = true;
      push.followTags = true;

      rebase.autoStash = true;
      rebase.autoSquash = true;
      rebase.updateRefs = true;

      rerere.enabled = true;
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
