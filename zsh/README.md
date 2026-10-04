# Zsh Config

The Zsh directory is linked out of the Nix store to `~/.config/zsh`. Edit the
file for each concern here; `nix/home/shell.nix` reads `init.zsh` as Home
Manager's startup content.

| Concern | File |
| --- | --- |
| Startup file loading | `init.zsh` |
| Environment defaults | `environment.zsh` |
| Aliases | `aliases.zsh` |
| Key bindings | `keybindings.zsh` |
| Completion and fzf matching | `completion.zsh` |
| Powerlevel10k theme and prompt loading | `integrations.zsh` |
| Shared optional tool integrations | `extra.zsh` |
| Home Manager command wrapper | `home-manager.zsh` |
| Host-only integrations | `local.zsh` |

Edits to these Zsh files are available to new shells immediately through the
out-of-store link. Restart a shell to load the changes there. Changes to
`init.zsh` or the Home Manager wiring take effect after `home-manager switch`.

`extra.zsh` holds optional integrations shared by this dotfiles checkout. Put
integrations for only one host in `local.zsh`; that file is gitignored and
loaded only when present. Powerlevel10k is also optional: the theme is loaded
from `~/powerlevel10k/powerlevel10k.zsh-theme` when present, and the private
`~/.p10k.zsh` remains owned by the host. Neither needs to be copied into this
repository.

Legacy backups such as `~/.zshrc.backup` are reference material only and are
not active configuration.
