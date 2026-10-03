# Configuration inventory and scope

Reviewed on 2026-10-04. This inventory uses tracked repository sources and
configuration-path presence in the current home directory. Authentication
contents, editor service-state contents, and bulk application preference
contents were not copied or read.

## Currently managed

| Area | Repository source | Apply method |
| --- | --- | --- |
| CLI packages | `nix/packages.nix`, `nix/home/packages.nix` | Home Manager with `nix run "path:$PWD#switch"` |
| Git preferences | `nix/home/git.nix` | Home Manager with `nix run "path:$PWD#switch"` |
| Zsh and Fish | `nix/home/shell.nix`, `zsh/`, `fish/` | Home Manager with `nix run "path:$PWD#switch"` |
| Powerlevel10k prompt config | `zsh/p10k.zsh` | Home Manager links it to `~/.p10k.zsh`; run `nix run "path:$PWD#switch"` |
| Ghostty | `ghostty/config` | Home Manager with `nix run "path:$PWD#switch"` |
| Codex and Claude instructions and skills | `codex/`, `ai/skills/`, `nix/home/ai.nix` | Home Manager with `nix run "path:$PWD#switch"` |
| macOS defaults | `nix/darwin/default.nix` | nix-darwin with `nix run "path:$PWD#darwin-switch"` |

The macOS defaults currently declare `AppleShowAllExtensions` and Dock
auto-hide. The Home Manager switch app backs up conflicting files with the
`hm-backup` extension.

## Intentionally local

- GitHub CLI authentication at `~/.config/gh/hosts.yml` stays local. It contains
  credentials and must never be added to the repository. The adjacent
  `~/.config/gh/config.yml` remains local until its portable preferences can be
  separated from account-specific configuration.
- VS Code user files are present because `code --wait` is the configured
  editor. `settings.json` and `keybindings.json` remain local pending a focused
  portability review. `mcp.json` and `chatLanguageModels.json` are private
  service and model state and stay outside the repository.
- The Powerlevel10k theme checkout at `~/powerlevel10k` remains a locally
  installed dependency. This change manages the prompt preferences; it does not
  vendor or pin the theme code.
- Other files under `~/Library/Preferences` are app and machine state. They
  remain local unless individual preferences are explicitly selected and
  expressed declaratively.

## Candidate decisions

| Candidate | Decision | Reason | Source of truth and apply method |
| --- | --- | --- | --- |
| Powerlevel10k | Include | Its config is actively sourced by Zsh and contains portable prompt preferences. | `zsh/p10k.zsh`, linked to `~/.p10k.zsh` by Home Manager; apply with `nix run "path:$PWD#switch"`. |
| GitHub CLI (`gh`) | Defer | Its config is separate from authentication, but its preferences have not been curated for portability. | Existing `~/.config/gh/config.yml` remains the local source; manage selected preferences in a later change. |
| VS Code settings and keybindings | Defer | Review portable editor preferences separately from MCP and model state. | Existing VS Code User files remain the local source and are edited in VS Code; no repository apply method is selected. |
| Additional macOS defaults | Defer | Avoid bulk-exporting per-app and machine state; add only named preferences. | Add future selections to `nix/darwin/default.nix` and apply with `nix run "path:$PWD#darwin-switch"`. |

The next addition is limited to the Powerlevel10k prompt configuration. Keep
authentication, generated state, and machine-specific paths out of the repo;
record an explicit decision here before adding another settings area.
