# Zsh Config

Base Zsh behavior is managed by Home Manager in `nix/home/shell.nix`.

Use `extra.zsh` for local integrations that are not yet modeled in Nix, such as tool-specific PATH additions or shell completions.

Legacy backups like `~/.zshrc.backup` are reference material only and should not be treated as active configuration.
